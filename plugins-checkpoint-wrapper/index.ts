/**
 * CheckpointContextEngine Plugin for OpenClaw
 * 
 * Wraps the registered ContextEngine (typically lossless-claw) with 
 * nanobot-style checkpoint/resume for in-progress turns.
 * 
 * Load order: This plugin MUST load AFTER lossless-claw.
 * In openclaw.json, ensure plugins.loadOrder places checkpoint after lossless-claw.
 * 
 * Alternatively, this plugin can be loaded as a workspace plugin via
 * openclaw.json plugins.entries.checkpoint-wrapper.config.wrapped = "lossless-claw"
 */

import { join } from "node:path";
import { existsSync } from "node:fs";
import type { OpenClawPluginApi } from "openclaw/plugin-sdk";
import { CheckpointContextEngine } from "./src/checkpoint-engine.js";

function resolveStorePath(agentDir: string): string {
  return join(agentDir, "checkpoints", "turn-checkpoints.json");
}

export default {
  id: "checkpoint-wrapper",
  name: "Checkpoint Context Engine",
  description:
    "nanobot-style checkpoint/resume wrapper for ContextEngine — saves in-progress turns before compact, restores after. Must load AFTER the wrapped context engine (e.g. lossless-claw).",

  configSchema: {
    parse(value: unknown) {
      const raw =
        value && typeof value === "object" && !Array.isArray(value)
          ? (value as Record<string, unknown>)
          : {};
      return {
        wrapped: typeof raw.wrapped === "string" ? raw.wrapped.trim() : "lossless-claw",
        storePath: typeof raw.storePath === "string" ? raw.storePath.trim() : "",
        enabled: raw.enabled !== false,
      };
    },
  },

  register(api: OpenClawPluginApi) {
    const rawConfig = api.pluginConfig && typeof api.pluginConfig === "object"
      ? (api.pluginConfig as Record<string, unknown>)
      : {};

    const config = {
      wrapped: typeof rawConfig.wrapped === "string" ? (rawConfig.wrapped as string).trim() : "lossless-claw",
      storePath: typeof rawConfig.storePath === "string" ? (rawConfig.storePath as string).trim() : "",
      enabled: rawConfig.enabled !== false,
    };

    if (!config.enabled) {
      api.logger.info("[checkpoint-wrapper] Disabled by config, skipping");
      return;
    }

    const storePath = config.storePath || resolveStorePath(api.resolvePath("."));
    api.logger.info(
      `[checkpoint-wrapper] Starting — wrapping engine "${config.wrapped}", store: ${storePath}`
    );

    // ── Try to get already-registered engine ──────────────────────────────────
    let wrappedFactory: (() => any) | null = null;

    // OpenClaw stores context engine factories. Try to find the wrapped one.
    const apiAny = api as any;
    if (typeof apiAny.registerContextEngine === "function") {
      // We're being registered AFTER lossless-claw typically.
      // The last registered factory wins. We need to find "lossless-claw".
      // 
      // Approach: since we can't access other factories directly,
      // we register ourselves AS the default AND wrapped engine.
      // The actual wrapping happens in a deferred setup below.
      apiAny.registerContextEngine(`checkpoint:${config.wrapped}`, () => {
        // This factory will be called when OpenClaw builds its context engine.
        // We need to return a CheckpointContextEngine that wraps the real one.
        // Since we can't get the real factory here, we use a lazy initialization:
        // create the wrapper on first use, caching the wrapped engine.
        return createDeferredWrapper(storePath, api, config.wrapped);
      });
      apiAny.registerContextEngine("default", () => {
        return createDeferredWrapper(storePath, api, config.wrapped);
      });
      apiAny.registerContextEngine("checkpoint", () => {
        return createDeferredWrapper(storePath, api, config.wrapped);
      });
    } else {
      api.logger.warn("[checkpoint-wrapper] registerContextEngine not available, cannot wrap engines");
    }
  },
};

/** Deferred wrapper factory — resolves the underlying engine lazily. */
function createDeferredWrapper(
  storePath: string,
  api: OpenClawPluginApi,
  engineName: string,
) {
  let cachedWrapper: CheckpointContextEngine | null = null;
  let initAttempts = 0;
  const MAX_ATTEMPTS = 3;

  return (): ContextEngine => {
    if (cachedWrapper) return cachedWrapper;

    initAttempts++;
    api.logger.debug(`[checkpoint-wrapper] Resolving wrapped engine (attempt ${initAttempts}/${MAX_ATTEMPTS})`);

    // Try to get the already-instantiated engine from OpenClaw's runtime.
    // OpenClaw stores the engine instance in api.runtime.context._engine (internal).
    const apiAny = api as any;
    let wrapped: ContextEngine | null = null;

    // Strategy 1: Try internal registry (newer OpenClaw versions)
    try {
      const ctx = apiAny.runtime?.context;
      if (ctx) {
        // Check for instantiated engine
        const engine = (ctx as any)._engine ?? (ctx as any).engine ?? null;
        if (engine && typeof (engine as any).compact === "function") {
          wrapped = engine as ContextEngine;
          api.logger.info(`[checkpoint-wrapper] Wrapped engine found via runtime.context._engine`);
        }
        // Check for factory registry
        const factories = (ctx as any)._factories ?? (ctx as any).factories ?? null;
        if (!wrapped && factories && typeof factories.get === "function") {
          const factory = factories.get(engineName);
          if (typeof factory === "function") {
            wrapped = (factory as () => ContextEngine)();
            api.logger.info(`[checkpoint-wrapper] Wrapped engine resolved via factory.get("${engineName}")`);
          }
        }
        // Check for default factory
        if (!wrapped && factories && typeof factories.get === "function") {
          const defaultFactory = factories.get("default");
          if (typeof defaultFactory === "function") {
            wrapped = (defaultFactory as () => ContextEngine)();
            api.logger.info(`[checkpoint-wrapper] Wrapped engine resolved via factory.get("default")`);
          }
        }
      }
    } catch (err) {
      api.logger.debug(`[checkpoint-wrapper] Strategy 1 failed: ${err}`);
    }

    // Strategy 2: Try direct module import (workspace plugins)
    if (!wrapped) {
      try {
        // Try to dynamically import lossless-claw from the workspace
        const possiblePaths = [
          join(api.resolvePath("."), "plugins-lossless-claw-enhanced", "src", "engine.js"),
          join(api.resolvePath("."), "..", "plugins-lossless-claw-enhanced", "src", "engine.js"),
          join(process.cwd(), "plugins-lossless-claw-enhanced", "src", "engine.js"),
        ];
        for (const p of possiblePaths) {
          if (existsSync(p)) {
            api.logger.debug(`[checkpoint-wrapper] Trying lossless-claw at ${p}`);
            // Can't directly import ESM with dynamic path — skip
          }
        }
      } catch (err) {
        api.logger.debug(`[checkpoint-wrapper] Strategy 2 failed: ${err}`);
      }
    }

    // Strategy 3: If we can't find the wrapped engine, create a passthrough
    if (!wrapped) {
      if (initAttempts >= MAX_ATTEMPTS) {
        api.logger.error(
          `[checkpoint-wrapper] Could not resolve wrapped engine "${engineName}" after ${MAX_ATTEMPTS} attempts. ` +
            `Falling back to passthrough (no checkpointing).`
        );
        // Return a minimal passthrough engine
        return createPassthroughEngine(api);
      }
      // Retry next time
      api.logger.debug(`[checkpoint-wrapper] Engine not ready yet, will retry on next access`);
      return createPassthroughEngine(api);
    }

    const logger = {
      info: (m: string) => api.logger.info(`[checkpoint] ${m}`),
      warn: (m: string) => api.logger.warn(`[checkpoint] ${m}`),
      error: (m: string) => api.logger.error(`[checkpoint] ${m}`),
      debug: (m: string) => api.logger.debug(`[checkpoint] ${m}`),
    };

    cachedWrapper = new CheckpointContextEngine(wrapped!, storePath, logger);
    api.logger.info(`[checkpoint-wrapper] Checkpoint wrapper active — wrapping ${wrapped!.info.id}`);
    return cachedWrapper;
  };
}

/** Minimal passthrough engine when we can't find the wrapped engine. */
function createPassthroughEngine(api: OpenClawPluginApi): ContextEngine {
  api.logger.warn("[checkpoint-wrapper] Using passthrough engine (checkpointing disabled)");
  return {
    get info() {
      return {
        id: "checkpoint:passthrough",
        name: "Checkpoint Passthrough",
        ownsCompaction: false,
      };
    },
    async bootstrap(params: any) {
      throw new Error("Passthrough engine: no wrapped engine available");
    },
    async compact(params: any) {
      return { actionTaken: false, tokensBefore: 0, tokensAfter: 0, condensed: false };
    },
    async assemble(params: any) {
      return { summary: "", context: [] };
    },
    async ingest(params: any) {
      return { sessionId: params.sessionId ?? "", tokensIngested: 0 };
    },
    async ingestBatch(params: any) {
      return { sessionId: params.sessionKey ?? params.sessionId ?? "", tokensIngested: 0 };
    },
    async prepareSubagentSpawn(params: any) {
      return { sessionKey: params.sessionKey ?? "", systemPrompt: "", messages: [] };
    },
    async onSubagentEnd(params: any) {},
  };
}
