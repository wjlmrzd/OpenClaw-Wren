/**
 * Checkpoint persistence layer — append-only JSON file per session.
 * 
 * Implements nanobot-style turn checkpoints:
 * - assistant_message: the incomplete assistant message (may have tool_calls, no tool results yet)
 * - completed_tool_results: tool results already received
 * - pending_tool_calls: tool calls waiting for results
 * - session_tail: raw messages from the last N turns before compaction
 * 
 * Unlike nanobot (in-memory), we persist to disk so checkpoints survive process restart.
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import { join, dirname } from "node:path";

export interface TurnCheckpoint {
  sessionKey: string;
  /** Timestamp when checkpoint was saved (ISO-8601) */
  savedAt: string;
  /** Index of last DB message BEFORE this checkpoint */
  lastDbIndex: number;
  /** Raw assistant message with pending tool_calls */
  assistantMessage: unknown | null;
  /** Tool call IDs that are still pending (no result yet) */
  pendingToolCallIds: string[];
  /** Tool results already received for this turn */
  completedToolResults: unknown[];
  /** Session tail: last N raw messages from session file */
  sessionTail: unknown[];
  /** Version for forward compatibility */
  version: 1;
}

interface CheckpointStore {
  [sessionKey: string]: TurnCheckpoint;
}

const STORE_VERSION = 1;
const STORE_MAGIC = "ckpt-v1";

/** Check if a checkpoint represents a genuine in-progress turn. */
export function isValidCheckpoint(cp: TurnCheckpoint): boolean {
  // Must have either a pending assistant message or completed tool results
  if (!cp.assistantMessage && cp.completedToolResults.length === 0) {
    return false;
  }
  // Must be recent (within 1 hour)
  try {
    const age = Date.now() - new Date(cp.savedAt).getTime();
    if (age > 60 * 60 * 1000) {
      return false;
    }
  } catch {
    return false;
  }
  return true;
}

/** Read the checkpoint store from disk. */
function readStore(storePath: string): CheckpointStore {
  try {
    if (!existsSync(storePath)) {
      return {};
    }
    const raw = readFileSync(storePath, "utf8");
    if (!raw.startsWith(STORE_MAGIC)) {
      return {};
    }
    const json = raw.slice(STORE_MAGIC.length);
    const parsed = JSON.parse(json);
    if (!parsed || typeof parsed !== "object") {
      return {};
    }
    return parsed as CheckpointStore;
  } catch {
    return {};
  }
}

/** Write the checkpoint store to disk atomically. */
function writeStore(storePath: string, store: CheckpointStore): void {
  const dir = dirname(storePath);
  if (!existsSync(dir)) {
    mkdirSync(dir, { recursive: true });
  }
  const json = JSON.stringify(store, null, 2);
  writeFileSync(storePath, STORE_MAGIC + json, "utf8");
}

/** Load checkpoint for a specific session. */
export function loadCheckpoint(storePath: string, sessionKey: string): TurnCheckpoint | null {
  const store = readStore(storePath);
  const cp = store[sessionKey];
  if (!cp) return null;
  if (!isValidCheckpoint(cp)) {
    // Clean up stale checkpoint
    delete store[sessionKey];
    writeStore(storePath, store);
    return null;
  }
  return cp;
}

/** Save checkpoint for a session. */
export function saveCheckpoint(storePath: string, checkpoint: TurnCheckpoint): void {
  const store = readStore(storePath);
  store[checkpoint.sessionKey] = checkpoint;
  writeStore(storePath, store);
}

/** Delete checkpoint for a session. */
export function deleteCheckpoint(storePath: string, sessionKey: string): void {
  const store = readStore(storePath);
  if (store[sessionKey]) {
    delete store[sessionKey];
    writeStore(storePath, store);
  }
}

/** List all active checkpoints. */
export function listCheckpoints(storePath: string): TurnCheckpoint[] {
  const store = readStore(storePath);
  return Object.values(store).filter(isValidCheckpoint);
}

/** Find the session tail (last N messages) from a session message array.
 * Returns messages that may span the boundary between saved turns and new turns.
 */
export function extractSessionTail(messages: unknown[], count: number): unknown[] {
  if (!Array.isArray(messages)) return [];
  if (messages.length <= count) return [...messages];
  return messages.slice(-count);
}

/** Detect if a message sequence represents an in-progress tool turn.
 * Returns { hasInProgressTurn, pendingToolCalls, completedToolResults }
 */
export function detectInProgressTurn(messages: unknown[]): {
  hasInProgressTurn: boolean;
  assistantMessage: unknown | null;
  pendingToolCallIds: string[];
  completedToolResults: unknown[];
} {
  if (!Array.isArray(messages) || messages.length === 0) {
    return { hasInProgressTurn: false, assistantMessage: null, pendingToolCallIds: [], completedToolResults: [] };
  }

  // Walk backwards from the end to find the last user message
  let lastUserIdx = -1;
  for (let i = messages.length - 1; i >= 0; i--) {
    const m = messages[i] as Record<string, unknown>;
    if (m?.role === "user") {
      lastUserIdx = i;
      break;
    }
  }

  if (lastUserIdx < 0) {
    // No user message found — check if there's an incomplete assistant turn at the end
    const last = messages[messages.length - 1] as Record<string, unknown>;
    if (last?.role === "assistant" && last?.tool_calls && Array.isArray(last.tool_calls) && last.tool_calls.length > 0) {
      const toolCalls = last.tool_calls as Array<Record<string, unknown>>;
      const completedIds = new Set<string>();
      for (let i = messages.length - 1; i >= 0; i--) {
        const m = messages[i] as Record<string, unknown>;
        if (m?.role !== "tool") break;
        const id = (m.tool_call_id as string) || (m.call_id as string);
        if (id) completedIds.add(id);
      }
      const pendingIds = toolCalls
        .map((tc) => (tc.id as string) || ((tc.function as Record<string, unknown>)?.name as string))
        .filter(Boolean);
      const hasPending = pendingIds.some((id) => !completedIds.has(id));
      if (hasPending) {
        return {
          hasInProgressTurn: true,
          assistantMessage: last,
          pendingToolCallIds: pendingIds.filter((id) => !completedIds.has(id)),
          completedToolResults: messages.slice(messages.length - completedIds.size).filter(
            (m) => (m as Record<string, unknown>).role === "tool"
          ),
        };
      }
    }
    return { hasInProgressTurn: false, assistantMessage: null, pendingToolCallIds: [], completedToolResults: [] };
  }

  // Check if there's an in-progress turn after the last user message
  const turnMessages = messages.slice(lastUserIdx);
  const lastAssistant = turnMessages[turnMessages.length - 1] as Record<string, unknown> | undefined;

  if (!lastAssistant || lastAssistant.role !== "assistant") {
    return { hasInProgressTurn: false, assistantMessage: null, pendingToolCallIds: [], completedToolResults: [] };
  }

  // Check if assistant has pending tool calls
  const toolCalls = lastAssistant.tool_calls;
  if (!toolCalls || !Array.isArray(toolCalls) || toolCalls.length === 0) {
    return { hasInProgressTurn: false, assistantMessage: null, pendingToolCallIds: [], completedToolResults: [] };
  }

  // Find all tool results after the last user message
  const toolResults: unknown[] = [];
  const completedIds = new Set<string>();
  for (const m of turnMessages.slice(1)) {
    const rec = m as Record<string, unknown>;
    if (rec?.role === "tool") {
      toolResults.push(m);
      const id = (rec.tool_call_id as string) || (rec.call_id as string);
      if (id) completedIds.add(id);
    }
  }

  // Check if any tool calls are still pending
  const pendingIds = (toolCalls as Array<Record<string, unknown>>)
    .map((tc) => (tc.id as string) || ((tc.function as Record<string, unknown>)?.name as string))
    .filter(Boolean);
  const hasPending = pendingIds.some((id) => !completedIds.has(id));

  return {
    hasInProgressTurn: hasPending,
    assistantMessage: hasPending ? lastAssistant : null,
    pendingToolCallIds: pendingIds.filter((id) => !completedIds.has(id)),
    completedToolResults: toolResults,
  };
}
