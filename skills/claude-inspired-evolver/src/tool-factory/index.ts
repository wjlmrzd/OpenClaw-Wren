/**
 * tool-factory / index.ts
 * 
 * 标准化 Tool 工厂 - 借鉴 Claude Code 的 Tool.ts buildTool 模式
 * 
 * 设计原则：
 * 1. 单一职责：每个工厂只创建一个 tool
 * 2. 策略内嵌：schema 校验、policy 检查都在工厂里完成
 * 3. 类型安全：使用 TypeScript + JSON Schema
 * 4. 错误隔离：handler 出错不会崩溃
 * 5. 可观测：每个调用都有日志
 * 
 * Claude Code 的 buildTool 模式：
 *   buildTool({
 *     name: string,
 *     description: string,
 *     schema: JSONSchema,
 *     handler: (params) => Promise<Result>,
 *     policy?: PolicyRule[],
 *   }) => Tool
 * 
 * OpenClaw 当前问题：
 * - schema 定义分散在各个 tool 文件
 * - 没有统一的错误处理
 * - 没有 policy 层的抽象
 * - 日志不统一
 */

import { Type, TSchema, Static } from '@sinclair/typebox';
import { Value } from '@sinclair/typebox/value';

// ── 类型定义 ──────────────────────────────────────────────

export interface ToolDefinition {
  name: string;
  description: string;
  schema: TSchema;
  /** 政策规则：定义何时允许/拒绝此工具调用 */
  policy?: PolicyRule[];
}

export interface PolicyRule {
  /** 条件类型 */
  type: 'allow' | 'deny' | 'require_param';
  /** 描述 */
  description: string;
  /** 检查函数 */
  check: (params: unknown, context: PolicyContext) => PolicyResult;
}

export interface PolicyContext {
  sessionKey: string;
  userId?: string;
  channel?: string;
  workspaceDir?: string;
}

export interface PolicyResult {
  allowed: boolean;
  reason?: string;
}

export interface ToolResult {
  success: boolean;
  content: unknown;
  error?: string;
  metadata?: Record<string, unknown>;
}

export type ToolHandler<TParams = unknown> = (
  params: TParams,
  context: PolicyContext,
) => Promise<ToolResult>;

// ── 策略引擎 ──────────────────────────────────────────────

/**
 * 执行策略检查
 */
export function checkPolicy(
  rules: PolicyRule[],
  params: unknown,
  context: PolicyContext,
): { allowed: boolean; reason?: string } {
  for (const rule of rules) {
    const result = rule.check(params, context);
    if (!result.allowed) {
      return { allowed: false, reason: `[${rule.type.toUpperCase()}] ${rule.description}: ${result.reason ?? 'denied'}` };
    }
  }
  return { allowed: true };
}

// ── 工厂函数 ──────────────────────────────────────────────

/**
 * buildTool - 统一的 Tool 创建工厂
 * 
 * @example
 * ```typescript
 * import { buildTool, stringEnum } from './tool-factory';
 * 
 * const myTool = buildTool({
 *   name: 'my-tool',
 *   description: 'Do something useful',
 *   schema: Type.Object({
 *     action: stringEnum(['do', 'undo']),
 *     target: Type.String(),
 *   }),
 *   policy: [
 *     {
 *       type: 'deny',
 *       description: '禁止在生产环境删除',
 *       check: (params, ctx) => ({
 *         allowed: !(params.action === 'undo' && ctx.workspaceDir?.includes('prod'))
 *       })
 *     }
 *   ],
 *   handler: async (params, ctx) => {
 *     // params 已经过 schema 校验
 *     const result = await doSomething(params.action, params.target);
 *     return { success: true, content: result };
 *   }
 * });
 * ```
 */
export function buildTool<T extends TSchema>(config: {
  name: string;
  description: string;
  schema: T;
  policy?: PolicyRule[];
  handler: ToolHandler<Static<T>>;
  /** 是否在 schema 校验失败时仍尝试调用 handler（不推荐） */
  allowUnvalidated?: boolean;
}): ToolDefinition & {
  execute: (params: unknown, context: PolicyContext) => Promise<ToolResult>;
  validate: (params: unknown) => { valid: boolean; params?: Static<T>; errors?: string };
} {
  const { name, description, schema, policy = [], handler, allowUnvalidated = false } = config;

  // ── Schema 校验 ────────────────────────────────────
  function validate(params: unknown): { valid: boolean; params?: Static<T>; errors?: string } {
    if (allowUnvalidated) {
      return { valid: true, params: params as Static<T> };
    }
    try {
      const errors = [...Value.Errors(schema, params)];
      if (errors.length > 0) {
        return {
          valid: false,
          errors: errors.map(e => `${e.path}: ${e.message}`).join('; '),
        };
      }
      return { valid: true, params: params as Static<T> };
    } catch (err) {
      return { valid: false, errors: String(err) };
    }
  }

  // ── 执行函数 ────────────────────────────────────────
  async function execute(params: unknown, context: PolicyContext): Promise<ToolResult> {
    const start = Date.now();
    
    // 1. Schema 校验
    const { valid, params: validatedParams, errors } = validate(params);
    if (!valid) {
      return {
        success: false,
        content: null,
        error: `Schema validation failed: ${errors}`,
        metadata: { name, durationMs: Date.now() - start },
      };
    }

    // 2. Policy 检查
    const { allowed, reason } = checkPolicy(policy, validatedParams, context);
    if (!allowed) {
      return {
        success: false,
        content: null,
        error: reason ?? 'Policy denied',
        metadata: { name, durationMs: Date.now() - start },
      };
    }

    // 3. 执行 handler
    try {
      const result = await handler(validatedParams!, context);
      const duration = Date.now() - start;
      console.log(`[Tool:${name}] OK ${duration}ms`);
      return {
        ...result,
        metadata: { ...result.metadata, name, durationMs: duration },
      };
    } catch (err) {
      const duration = Date.now() - start;
      console.error(`[Tool:${name}] ERROR ${duration}ms`, err);
      return {
        success: false,
        content: null,
        error: err instanceof Error ? err.message : String(err),
        metadata: { name, durationMs: duration },
      };
    }
  }

  return {
    name,
    description,
    schema,
    policy,
    execute,
    validate,
  };
}

// ── 常用 Schema 辅助 ─────────────────────────────────────

/** 创建字符串枚举类型 */
export function stringEnum<T extends string[]>(values: [...T]) {
  return Type.Union(values.map(v => Type.Literal(v)));
}

/** 创建可选字符串枚举 */
export function optionalStringEnum<T extends string[]>(values: [...T]) {
  return Type.Optional(Type.Union(values.map(v => Type.Literal(v))));
}

/** 常用 schema 模式 */
export const CommonSchemas = {
  /** 超时参数（毫秒） */
  timeoutMs: Type.Optional(Type.Number({ minimum: 1000, maximum: 120000, default: 30000 })),
  
  /** 通用 ID 参数 */
  id: Type.String({ minLength: 1, maxLength: 200 }),
  
  /** Session key */
  sessionKey: Type.String({ minLength: 1 }),
  
  /** 分页限制 */
  limit: Type.Optional(Type.Number({ minimum: 1, maximum: 100, default: 20 })),
};

// ── 结果格式化 ─────────────────────────────────────────────

/**
 * 标准 JSON 结果（供 tool return 使用）
 */
export function jsonResult(content: unknown): ToolResult {
  return { success: true, content };
}

/**
 * 标准错误结果
 */
export function errorResult(error: string): ToolResult {
  return { success: false, content: null, error };
}

/**
 * 读取字符串参数（支持 content object 格式）
 */
export function readStringParam(params: unknown, key: string): string | undefined {
  if (!params || typeof params !== 'object') return undefined;
  const p = params as Record<string, unknown>;
  const val = p[key];
  if (typeof val === 'string') return val;
  return undefined;
}

// ── 预置 Policy 规则 ─────────────────────────────────────

/** 禁止空字符串参数 */
export function requireNonEmpty(param: string, paramName: string): PolicyRule {
  return {
    type: 'require_param',
    description: `${paramName} 不能为空`,
    check: () => ({
      allowed: param.trim().length > 0,
      reason: param.trim().length === 0 ? `${paramName} is empty` : undefined,
    }),
  };
}

/** Workspace 边界检查 */
export function workspaceBoundaryCheck(
  getWorkspaceDir: (ctx: PolicyContext) => string | undefined,
): PolicyRule {
  return {
    type: 'deny',
    description: '文件操作不能超出 workspace',
    check: (_params, ctx) => {
      const workspace = getWorkspaceDir(ctx);
      if (!workspace) return { allowed: true };
      // 具体实现依赖于检查文件路径是否在 workspace 内
      return { allowed: true }; // 占位，后续完善
    },
  };
}
