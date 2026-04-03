/**
 * cost-tracker / index.ts
 * 
 * 独立成本追踪器 - 借鉴 Claude Code 的 cost-tracker.ts 设计
 * 
 * 功能：
 * 1. 记录每次 LLM 调用的 token 消耗和费用
 * 2. 维护每个 session 的运行成本
 * 3. 提供格式化输出
 * 4. 持久化存储，支持历史查询
 * 
 * 使用方式：
 * - 每次 LLM 调用后调用 trackCall()
 * - 查询当前 session: getSessionCost(sessionKey)
 * - 查询所有时间: getTotalCost()
 * - 格式化输出: formatCostReport()
 */

import { calculateCallCost, type ModelPricing } from './pricing.js';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';

export interface Usage {
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
  total: number;
}

export interface CallRecord {
  timestamp: number;
  sessionKey: string;
  modelId: string;
  provider: string;
  usage: Usage;
  cost: number;
  isFree: boolean;
}

export interface SessionCost {
  sessionKey: string;
  totalCalls: number;
  totalTokens: number;
  totalCost: number;
  isFree: boolean;
  calls: CallRecord[];
}

interface CostStore {
  sessions: Record<string, SessionCost>;
  globalTotal: {
    totalCalls: number;
    totalTokens: number;
    totalCost: number;
  };
}

// ── 存储路径 ──────────────────────────────────────────────

function getStorePath(): string {
  const workspace = 'D:\\OpenClaw\\.openclaw\\workspace';
  const dir = join(workspace, 'memory', 'cost-tracker');
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
  return join(dir, 'store.json');
}

function loadStore(): CostStore {
  const path = getStorePath();
  if (!existsSync(path)) {
    return { sessions: {}, globalTotal: { totalCalls: 0, totalTokens: 0, totalCost: 0 } };
  }
  try {
    return JSON.parse(readFileSync(path, 'utf-8'));
  } catch {
    return { sessions: {}, globalTotal: { totalCalls: 0, totalTokens: 0, totalCost: 0 } };
  }
}

function saveStore(store: CostStore): void {
  const path = getStorePath();
  writeFileSync(path, JSON.stringify(store, null, 2), 'utf-8');
}

// ── 核心追踪 ──────────────────────────────────────────────

/**
 * 记录一次 LLM 调用
 * @param params - 调用参数
 */
export function trackCall(params: {
  sessionKey: string;
  modelId: string;
  provider: string;
  usage: Usage;
}): CallRecord {
  const { sessionKey, modelId, provider, usage } = params;
  const { cost, isFree, breakdown } = calculateCallCost(
    modelId,
    usage.input ?? 0,
    usage.output ?? 0,
    usage.cacheRead ?? 0,
    usage.cacheWrite ?? 0,
  );

  const record: CallRecord = {
    timestamp: Date.now(),
    sessionKey,
    modelId,
    provider,
    usage,
    cost,
    isFree,
  };

  const store = loadStore();

  // 更新 session 记录
  if (!store.sessions[sessionKey]) {
    store.sessions[sessionKey] = {
      sessionKey,
      totalCalls: 0,
      totalTokens: 0,
      totalCost: 0,
      isFree: true,
      calls: [],
    };
  }
  const session = store.sessions[sessionKey];
  session.totalCalls += 1;
  session.totalTokens += usage.total ?? (usage.input ?? 0) + (usage.output ?? 0);
  session.totalCost += cost;
  session.isFree = session.isFree && isFree;
  session.calls.push(record);

  // 更新全局记录
  store.globalTotal.totalCalls += 1;
  store.globalTotal.totalTokens += usage.total ?? (usage.input ?? 0) + (usage.output ?? 0);
  store.globalTotal.totalCost += cost;

  saveStore(store);

  console.log(`[CostTracker] ${sessionKey} | ${modelId} | ${breakdown}`);
  return record;
}

/**
 * 获取某个 session 的成本统计
 */
export function getSessionCost(sessionKey: string): SessionCost | null {
  const store = loadStore();
  return store.sessions[sessionKey] ?? null;
}

/**
 * 获取全局总成本
 */
export function getTotalCost(): CostStore['globalTotal'] {
  const store = loadStore();
  return store.globalTotal;
}

/**
 * 获取所有 session 的成本摘要
 */
export function getAllSessionsCost(): SessionCost[] {
  const store = loadStore();
  return Object.values(store.sessions).sort((a, b) => b.totalCost - a.totalCost);
}

// ── 格式化输出 ─────────────────────────────────────────────

/**
 * 格式化成本报告（供 AI 读取或用户展示）
 */
export function formatCostReport(params?: {
  sessionKey?: string;
  includeDetails?: boolean;
}): string {
  const { sessionKey, includeDetails = false } = params ?? {};

  if (sessionKey) {
    const session = getSessionCost(sessionKey);
    if (!session) return `无 session "${sessionKey}" 的成本记录。`;

    const lines = [
      `## 💰 Session 成本报告`,
      ``,
      `| 项目 | 值 |`,
      `|------|-----|`,
      `| Session | \`${session.sessionKey}\` |`,
      `| 调用次数 | ${session.totalCalls} |`,
      `| 总 Token | ${session.totalTokens.toLocaleString()} |`,
      `| 总费用 | ${session.isFree ? '🆓 免费' : `$${session.totalCost.toFixed(6)}`} |`,
    ];

    if (includeDetails && session.calls.length > 0) {
      lines.push(``);
      lines.push(`### 最近调用`);
      lines.push(``);
      lines.push(`| 时间 | 模型 | Input | Output | 费用 |`);
      lines.push(`|------|------|-------|--------|------|`);
      for (const call of session.calls.slice(-10).reverse()) {
        const time = new Date(call.timestamp).toLocaleString('zh-CN', { hour: '2-digit', minute: '2-digit' });
        const costStr = call.isFree ? '🆓' : `$${call.cost.toFixed(6)}`;
        lines.push(`| ${time} | ${call.modelId} | ${call.usage.input?.toLocaleString() ?? '-'} | ${call.usage.output?.toLocaleString() ?? '-'} | ${costStr} |`);
      }
    }

    return lines.join('\n');
  }

  // 全局报告
  const total = getTotalCost();
  const sessions = getAllSessionsCost();
  const paidSessions = sessions.filter(s => !s.isFree && s.totalCost > 0);
  const freeSessions = sessions.filter(s => s.isFree || s.totalCost === 0);

  const lines = [
    `## 💰 全局成本报告`,
    ``,
    `| 项目 | 值 |`,
    `|------|-----|`,
    `| 总调用次数 | ${total.totalCalls.toLocaleString()} |`,
    `| 总 Token | ${total.totalTokens.toLocaleString()} |`,
    `| 总费用 | ${total.totalCost < 0.000001 ? '🆓 主要使用免费模型' : `$${total.totalCost.toFixed(6)}`} |`,
    `| 活跃 Session | ${sessions.length} |`,
    `| 付费 Session | ${paidSessions.length} |`,
  ];

  if (paidSessions.length > 0) {
    lines.push(``);
    lines.push(`### 付费 Session`);
    lines.push(``);
    lines.push(`| Session | 调用 | Token | 费用 |`);
    lines.push(`|---------|------|-------|------|`);
    for (const s of paidSessions.slice(0, 10)) {
      lines.push(`| \`${s.sessionKey}\` | ${s.totalCalls} | ${s.totalTokens.toLocaleString()} | $${s.totalCost.toFixed(6)} |`);
    }
  }

  if (freeSessions.length > 0) {
    lines.push(``);
    lines.push(`### 免费 Session (${freeSessions.length})`);
    for (const s of freeSessions.slice(0, 5)) {
      lines.push(`- \`${s.sessionKey}\` (${s.totalCalls} 调用, ${s.totalTokens.toLocaleString()} tokens)`);
    }
  }

  return lines.join('\n');
}

/**
 * 获取 markdown 格式的简洁摘要（适合嵌入 AI 上下文）
 */
export function getCostSummary(): string {
  const total = getTotalCost();
  if (total.totalCalls === 0) return '暂无成本记录。';
  
  const costStr = total.totalCost < 0.000001 
    ? '🆓' 
    : `$${total.totalCost.toFixed(6)}`;
  
  return `${total.totalCalls} calls, ${total.totalTokens.toLocaleString()} tokens, ${costStr}`;
}
