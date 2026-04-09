/**
 * CheckpointContextEngine — nanobot-style checkpoint/resume for OpenClaw.
 * 
 * Wraps a ContextEngine (typically lossless-claw) and adds:
 * 
 * 1. CHECKPOINT SAVE (before compact):
 *    - Detect in-progress turns (assistant msg with pending tool_calls)
 *    - Snapshot session tail (last messages from session file)
 *    - Persist checkpoint to disk
 * 
 * 2. TURN RESTORE (on assemble/bootstrap):
 *    - Check for saved checkpoint
 *    - Inject pending turn messages into the returned context
 *    - Mark checkpoint as "restored" (deleted after next successful turn)
 * 
 * Key insight (from nanobot loop.py):
 * - compact() fires BETWEEN turns
 * - assemble() is called to build context for the NEXT turn
 * - If we save the turn state before compact, we can restore it in assemble
 */

import type {
  ContextEngine,
  ContextEngineInfo,
  AssembleResult,
  CompactResult,
  IngestResult,
  IngestBatchResult,
  BootstrapResult,
  SubagentEndReason,
  SubagentSpawnPreparation,
} from "openclaw/plugin-sdk";

type WrappedEngineFactory = () => ContextEngine;

interface AssembleParams {
  sessionKey?: string;
  sessionId?: string;
  tokenBudget?: number;
  runtimeContext?: Record<string, unknown>;
  bootstrap?: boolean;
}

interface CompactParams {
  sessionKey?: string;
  sessionId?: string;
  reason?: string;
  runtimeContext?: Record<string, unknown>;
}

interface IngestParams {
  sessionKey?: string;
  sessionId?: string;
  message: unknown;
  metadata?: Record<string, unknown>;
}

interface BootstrapParams {
  sessionKey?: string;
  sessionId?: string;
  messages: unknown[];
  runtimeContext?: Record<string, unknown>;
}

export class CheckpointContextEngine implements ContextEngine {
  readonly info: ContextEngineInfo;
  private wrapped: ContextEngine;
  private storePath: string;
  private log: {
    info: (msg: string) => void;
    warn: (msg: string) => void;
    error: (msg: string) => void;
    debug: (msg: string) => void;
  };

  constructor(wrapped: ContextEngine, storePath: string, log?: {
    info: (msg: string) => void;
    warn: (msg: string) => void;
    error: (msg: string) => void;
    debug: (msg: string) => void;
  }) {
    this.wrapped = wrapped;
    this.storePath = storePath;
    this.log = log ?? {
      info: (m) => console.log(`[checkpoint] ${m}`),
      warn: (m) => console.warn(`[checkpoint] WARN: ${m}`),
      error: (m) => console.error(`[checkpoint] ERROR: ${m}`),
      debug: (m) => console.debug(`[checkpoint] DEBUG: ${m}`),
    };

    // Delegate info to wrapped engine but mark ourselves
    const wInfo = wrapped.info;
    this.info = {
      id: `checkpoint:${wInfo.id}`,
      name: `Checkpoint + ${wInfo.name}`,
      ownsCompaction: wInfo.ownsCompaction,
    };
  }

  // ── Delegated methods (pass through to wrapped engine) ─────────────────────

  async bootstrap(params: BootstrapParams): Promise<BootstrapResult> {
    return this.wrapped.bootstrap(params);
  }

  async ingest(params: IngestParams): Promise<IngestResult> {
    return this.wrapped.ingest(params);
  }

  async ingestBatch(params: {
    sessionKey?: string;
    sessionId?: string;
    messages: unknown[];
  }): Promise<IngestBatchResult> {
    return this.wrapped.ingestBatch(params);
  }

  async prepareSubagentSpawn(params: {
    sessionKey?: string;
    sessionId?: string;
    messages: unknown[];
  }): Promise<SubagentSpawnPreparation> {
    return this.wrapped.prepareSubagentSpawn(params);
  }

  async onSubagentEnd(params: {
    sessionKey?: string;
    sessionId?: string;
    reason: SubagentEndReason;
    result?: unknown;
  }): Promise<void> {
    return this.wrapped.onSubagentEnd(params);
  }

  // ── Wrapped assemble: restore checkpoint BEFORE building context ────────────

  async assemble(params: AssembleParams): Promise<AssembleResult> {
    const key = params.sessionKey ?? params.sessionId ?? "unknown";

    // Try to restore any saved checkpoint for this session
    try {
      const { loadCheckpoint } = await import("./store/checkpoint-store.js");
      const cp = loadCheckpoint(this.storePath, key);
      if (cp) {
        this.log.info(
          `[${key}] Found checkpoint from ${cp.savedAt}, pending tool calls: ${cp.pendingToolCallIds.length}`
        );
        // We'll inject the checkpoint into the wrapped assemble result
        // by temporarily storing it on the runtimeContext
        const enhancedContext = {
          ...params.runtimeContext,
          _checkpointRestore: {
            assistantMessage: cp.assistantMessage,
            completedToolResults: cp.completedToolResults,
            pendingToolCallIds: cp.pendingToolCallIds,
            savedAt: cp.savedAt,
          },
        };

        const result = await this.wrapped.assemble({
          ...params,
          runtimeContext: enhancedContext,
        });

        // Delete checkpoint after successful restore
        const { deleteCheckpoint } = await import("./store/checkpoint-store.js");
        deleteCheckpoint(this.storePath, key);
        this.log.info(`[${key}] Checkpoint restored and cleared`);

        return result;
      }
    } catch (err) {
      this.log.warn(`[${key}] Failed to load/restore checkpoint: ${err}`);
    }

    return this.wrapped.assemble(params);
  }

  // ── Wrapped compact: save checkpoint BEFORE compaction ───────────────────

  async compact(params: CompactParams): Promise<CompactResult> {
    const key = params.sessionKey ?? params.sessionId ?? "unknown";

    // STEP 1: Save checkpoint BEFORE compaction
    try {
      await this.saveCheckpoint(key, params);
    } catch (err) {
      this.log.warn(`[${key}] Failed to save checkpoint before compact: ${err}`);
    }

    // STEP 2: Run the actual compaction (wrapped engine may rebuild its DAG)
    const result = await this.wrapped.compact(params);

    // STEP 3: Verify the checkpoint is still valid ( compaction may have failed)
    try {
      const { loadCheckpoint, isValidCheckpoint } = await import("./store/checkpoint-store.js");
      const cp = loadCheckpoint(this.storePath, key);
      if (cp && isValidCheckpoint(cp)) {
        this.log.debug(
          `[${key}] Checkpoint preserved after compact (tokens: ${result.tokensBefore} → ${result.tokensAfter})`
        );
      } else if (cp) {
        const { deleteCheckpoint } = await import("./store/checkpoint-store.js");
        deleteCheckpoint(this.storePath, key);
        this.log.debug(`[${key}] Stale checkpoint cleared`);
      }
    } catch (err) {
      this.log.warn(`[${key}] Failed to verify checkpoint after compact: ${err}`);
    }

    return result;
  }

  // ── Checkpoint save logic ─────────────────────────────────────────────────

  private async saveCheckpoint(sessionKey: string, params: CompactParams): Promise<void> {
    // We need to get the current session messages to detect in-progress turns.
    // The wrapped engine has the session data. We use the runtimeContext if available.
    const rt = params.runtimeContext;

    let messages: unknown[] = [];
    if (rt?.messages && Array.isArray(rt.messages)) {
      messages = rt.messages as unknown[];
    } else if (rt?.history && Array.isArray(rt.history)) {
      messages = rt.history as unknown[];
    }

    if (messages.length === 0) {
      this.log.debug(`[${sessionKey}] No messages available for checkpoint`);
      return;
    }

    // Detect in-progress turn
    const { detectInProgressTurn, extractSessionTail, saveCheckpoint: doSave } = await import(
      "./store/checkpoint-store.js"
    );

    const turnState = detectInProgressTurn(messages);

    if (!turnState.hasInProgressTurn) {
      this.log.debug(`[${sessionKey}] No in-progress turn detected, skipping checkpoint`);
      return;
    }

    // Save checkpoint
    const { saveCheckpoint: persist } = await import("./store/checkpoint-store.js");
    persist(this.storePath, {
      sessionKey,
      savedAt: new Date().toISOString(),
      lastDbIndex: -1, // unknown at this point
      assistantMessage: turnState.assistantMessage,
      pendingToolCallIds: turnState.pendingToolCallIds,
      completedToolResults: turnState.completedToolResults,
      sessionTail: extractSessionTail(messages, 10),
      version: 1,
    });

    this.log.info(
      `[${sessionKey}] Checkpoint saved: ${turnState.pendingToolCallIds.length} pending tool calls, ` +
        `${turnState.completedToolResults.length} completed results`
    );
  }
}
