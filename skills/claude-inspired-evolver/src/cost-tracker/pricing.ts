/**
 * cost-tracker / pricing.ts
 * 
 * 模型定价表（美元/百万 tokens）
 * 数据来源：各 provider 官方定价页（2026-04 基准）
 * 
 * 使用说明：
 * 1. 优先从 openclaw.json 的 models[].cost 字段读取
 * 2. 未配置的模型使用此表的默认值
 * 3. 价格会变动，建议定期对照 provider 官方定价更新
 */

export interface ModelPricing {
  input: number;       // $/1M input tokens
  output: number;      // $/1M output tokens
  cacheRead: number;   // $/1M cache read (Anthropic)
  cacheWrite: number;  // $/1M cache write (Anthropic)
}

// 已知模型定价（$/1M tokens）
const PRICING_TABLE: Record<string, ModelPricing> = {
  // ── Anthropic ──────────────────────────────────────
  'claude-opus-4-5': { input: 15, output: 75, cacheRead: 1.5, cacheWrite: 18.75 },
  'claude-opus-4-6': { input: 15, output: 75, cacheRead: 1.5, cacheWrite: 18.75 },
  'claude-sonnet-4-5': { input: 3, output: 15, cacheRead: 0.3, cacheWrite: 3.75 },
  'claude-sonnet-4-6': { input: 3, output: 15, cacheRead: 0.3, cacheWrite: 3.75 },
  'claude-haiku-4': { input: 0.8, output: 4, cacheRead: 0.08, cacheWrite: 1.0 },

  // ── OpenAI ──────────────────────────────────────────
  'gpt-4o': { input: 2.5, output: 10, cacheRead: 0, cacheWrite: 0 },
  'gpt-4o-mini': { input: 0.15, output: 0.6, cacheRead: 0, cacheWrite: 0 },
  'gpt-4-turbo': { input: 10, output: 30, cacheRead: 0, cacheWrite: 0 },

  // ── DashScope (阿里云百炼) ───────────────────────────
  // 注意：DashScope 对中国区有独立定价，以下为国际版参考价
  // 实际价格请以阿里云百炼官网为准
  'qwen3.5-plus': { input: 0.2, output: 0.6, cacheRead: 0, cacheWrite: 0 },
  'qwen3-coder-plus': { input: 0.4, output: 1.2, cacheRead: 0, cacheWrite: 0 },
  'qwen3-coder-next': { input: 0.8, output: 2.0, cacheRead: 0, cacheWrite: 0 },
  'glm-5': { input: 0.1, output: 0.3, cacheRead: 0, cacheWrite: 0 },
  'glm-4.7': { input: 0.1, output: 0.3, cacheRead: 0, cacheWrite: 0 },
  'kimi-k2.5': { input: 0.5, output: 1.5, cacheRead: 0, cacheWrite: 0 },

  // ── MiniMax ─────────────────────────────────────────
  'minimax-2.7': { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },   // Coding Plan 免费
  'minimax-m2.5': { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },   // Coding Plan 免费

  // ── Ollama (本地) ───────────────────────────────────
  'llama3': { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },  // 本地运行无 API 成本
  'codellama': { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
  'qwen2.5': { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
};

/**
 * 根据模型 ID 获取定价
 * @param modelId - 模型 ID（支持带 provider 前缀或不带）
 */
export function getModelPricing(modelId: string): ModelPricing | null {
  if (!modelId) return null;

  // 尝试直接匹配
  if (PRICING_TABLE[modelId]) {
    return PRICING_TABLE[modelId];
  }

  // 去掉 provider 前缀再匹配 (e.g. "dashscope-coding-plan/qwen3.5-plus" -> "qwen3.5-plus")
  const withoutProvider = modelId.split('/').pop() ?? modelId;
  if (PRICING_TABLE[withoutProvider]) {
    return PRICING_TABLE[withoutProvider];
  }

  // fuzzy match: 检查 ID 中包含的关键词
  const lower = modelId.toLowerCase();
  for (const [key, pricing] of Object.entries(PRICING_TABLE)) {
    if (lower.includes(key) || key.includes(lower.replace(/[^a-z0-9.-]/g, ''))) {
      return pricing;
    }
  }

  return null;
}

/**
 * 计算一次调用的美元成本
 * @param modelId - 模型 ID
 * @param inputTokens - 输入 token 数
 * @param outputTokens - 输出 token 数
 * @param cacheRead - 缓存读取 token 数 (Anthropic)
 * @param cacheWrite - 缓存写入 token 数 (Anthropic)
 */
export function calculateCallCost(
  modelId: string,
  inputTokens: number,
  outputTokens: number,
  cacheRead = 0,
  cacheWrite = 0,
): { cost: number; isFree: boolean; breakdown: string } {
  const pricing = getModelPricing(modelId);

  if (!pricing) {
    return {
      cost: -1,
      isFree: false,
      breakdown: `模型 ${modelId} 定价未知`,
    };
  }

  // 全免费模型
  if (pricing.input === 0 && pricing.output === 0) {
    return {
      cost: 0,
      isFree: true,
      breakdown: `${modelId} (免费模型)`,
    };
  }

  const inputCost = (inputTokens / 1_000_000) * pricing.input;
  const outputCost = (outputTokens / 1_000_000) * pricing.output;
  const cacheReadCost = (cacheRead / 1_000_000) * pricing.cacheRead;
  const cacheWriteCost = (cacheWrite / 1_000_000) * pricing.cacheWrite;
  const total = inputCost + outputCost + cacheReadCost + cacheWriteCost;

  const parts: string[] = [];
  if (inputTokens > 0 && pricing.input > 0) parts.push(`${inputTokens.toLocaleString()} in × $${pricing.input}/M = $${inputCost.toFixed(6)}`);
  if (outputTokens > 0 && pricing.output > 0) parts.push(`${outputTokens.toLocaleString()} out × $${pricing.output}/M = $${outputCost.toFixed(6)}`);
  if (cacheRead > 0 && pricing.cacheRead > 0) parts.push(`cache read × $${pricing.cacheRead}/M = $${cacheReadCost.toFixed(6)}`);
  if (cacheWrite > 0 && pricing.cacheWrite > 0) parts.push(`cache write × $${pricing.cacheWrite}/M = $${cacheWriteCost.toFixed(6)}`);

  return {
    cost: total,
    isFree: false,
    breakdown: parts.join(' + ') + ` = $${total.toFixed(6)}`,
  };
}
