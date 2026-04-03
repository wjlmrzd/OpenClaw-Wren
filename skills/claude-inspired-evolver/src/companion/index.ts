/**
 * companion / index.ts
 * 
 * 伴侣系统 - 借鉴 Claude Code 的 buddy/ Tamagotchi 风格伴侣设计
 * 
 * Claude Code 的 companion 是一个"有存在感"的 AI：
 * - 主动在长时间无操作时发送提示
 * - 跟踪用户的行为模式
 * - 主动关心用户（训练、休息、工作节奏）
 * - 有自己的"个性"（温暖但不过度打扰）
 * 
 * OpenClaw 的等效实现：
 * - 运行在 session idle 时检测（通过 cron 或 heartbeat）
 * - 维护 Wren 的行为上下文
 * - 在自然时刻发送主动消息
 * - 不烦人——只在有意义的时候说话
 * 
 * 设计原则：
 * 1. 主动性：有价值才发，不凑数
 * 2. 个性一致：温暖的、关心的、不啰嗦的
 * 3. 情境感知：了解上下文，不乱插嘴
 * 4. 记忆：记住 Wren 的偏好和状态
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';

// ── 类型定义 ──────────────────────────────────────────────

export interface CompanionState {
  /** Wren 的称呼 */
  name: string;
  /** 核心偏好 */
  preferences: {
    /** Wren 典型的活跃时间段（小时，24h制） */
    activeHours: number[];
    /** Wren 是否有运动习惯 */
    hasExerciseHabit: boolean;
    /** Wren 当前的主要项目 */
    currentProjects: string[];
    /** 关注的健康指标 */
    health关注: string[];
  };
  /** 最后活跃状态 */
  lastActive: number;       // timestamp
  lastCheckIn: number;       // 最后一次"有意义"交互的时间
  lastCompanionMessage: number; // 上一次伴侣消息时间
  /** 情绪/能量状态（0-100） */
  energyLevel: number;
  /** 已发送的提醒（避免重复） */
  sentReminders: string[];  // 格式: "type:date" 如 "exercise:2026-04-03"
  /** 长期趋势 */
  trends: {
    avgDailyInteractions: number;
    totalInteractions: number;
    lastUpdated: number;
  };
}

export interface TriggerResult {
  shouldTrigger: boolean;
  message?: string;
  type?: 'idle' | 'exercise' | 'water' | 'break' | 'project' | 'health' | 'contextual';
  priority: 'low' | 'medium' | 'high';
}

// ── 状态存储 ──────────────────────────────────────────────

const STATE_FILE = join(
  'D:\\OpenClaw\\.openclaw\\workspace',
  'memory',
  'companion',
  'state.json'
);

function ensureStateDir(): void {
  const dir = STATE_FILE.substring(0, STATE_FILE.lastIndexOf('\\'));
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
}

export function loadState(): CompanionState {
  ensureStateDir();
  if (!existsSync(STATE_FILE)) {
    return getDefaultState();
  }
  try {
    const raw = readFileSync(STATE_FILE, 'utf-8');
    return { ...getDefaultState(), ...JSON.parse(raw) };
  } catch {
    return getDefaultState();
  }
}

export function saveState(state: CompanionState): void {
  ensureStateDir();
  writeFileSync(STATE_FILE, JSON.stringify(state, null, 2), 'utf-8');
}

function getDefaultState(): CompanionState {
  return {
    name: 'Wren',
    preferences: {
      activeHours: [8, 9, 10, 11, 14, 15, 16, 17, 20, 21, 22],
      hasExerciseHabit: true,
      currentProjects: [],
      health关注: ['跑步', '睡眠'],
    },
    lastActive: Date.now(),
    lastCheckIn: Date.now(),
    lastCompanionMessage: 0,
    energyLevel: 80,
    sentReminders: [],
    trends: {
      avgDailyInteractions: 0,
      totalInteractions: 0,
      lastUpdated: Date.now(),
    },
  };
}

// ── 上下文读取 ─────────────────────────────────────────────

/**
 * 从 MEMORY.md 和 daily logs 读取 Wren 当前状态
 */
export async function loadWrenContext(): Promise<{
  projects: string[];
  recentEvents: string[];
  trainingPlan?: string;
  health?: string;
}> {
  const memoryFiles = [
    'D:\\OpenClaw\\.openclaw\\workspace\\MEMORY.md',
    'D:\\OpenClaw\\.openclaw\\workspace\\memory\\2026-04-03.md',
    'D:\\OpenClaw\\.openclaw\\workspace\\memory\\running-training-plan.md',
  ];

  const projects: string[] = [];
  const recentEvents: string[] = [];

  for (const file of memoryFiles) {
    if (existsSync(file)) {
      try {
        const content = readFileSync(file, 'utf-8');
        if (file.includes('MEMORY.md')) {
          // 提取项目信息
          const projectMatch = content.match(/- \*\*(.+?)\*\*/g);
          if (projectMatch) projects.push(...projectMatch.map(m => m.replace(/\*\*/g, '')));
        }
        if (file.includes('running-training-plan')) {
          const weekMatch = content.match(/周数.*\|\s*\d+\s*\|[^\n]+\|[^\n]+\|[^\n]+\|/);
          if (weekMatch) recentEvents.push('训练: ' + weekMatch[0].split('|')[4]?.trim());
        }
        if (file.includes('2026-04-03')) {
          const lines = content.split('\n').filter(l => l.trim());
          recentEvents.push(...lines.slice(-5).map(l => l.substring(0, 80)));
        }
      } catch {
        // 忽略读取错误
      }
    }
  }

  return { projects, recentEvents };
}

// ── 触发检测 ──────────────────────────────────────────────

/** 检查是否应该发送主动消息 */
export function checkTriggers(state: CompanionState, now: Date): TriggerResult[] {
  const results: TriggerResult[] = [];
  const hour = now.getHours();
  const dayStr = now.toISOString().split('T')[0]; // "2026-04-03"

  // ── 1. 长时间空闲检测 ─────────────────────────────
  const idleMs = now.getTime() - state.lastActive;
  const idleHours = idleMs / (1000 * 60 * 60);

  if (idleHours >= 3) {
    results.push({
      shouldTrigger: true,
      message: undefined, // 使用上下文消息
      type: 'idle',
      priority: idleHours >= 6 ? 'high' : 'medium',
    });
  }

  // ── 2. 训练提醒（早7点/晚6点）─────────────────────
  if (hour === 7 && state.preferences.hasExerciseHabit) {
    const reminderKey = `exercise:${dayStr}`;
    if (!state.sentReminders.includes(reminderKey)) {
      results.push({
        shouldTrigger: true,
        message: `早安 ${state.name}！今天是运动日吗？🏃 记得去跑步～`,
        type: 'exercise',
        priority: 'medium',
      });
    }
  }

  // ── 3. 长时间工作后休息提醒 ───────────────────────
  // 连续工作 >2h 无休息
  const checkInMs = now.getTime() - state.lastCheckIn;
  const checkInHours = checkInMs / (1000 * 60 * 60);
  if (checkInHours >= 2 && hour >= 10 && hour <= 18) {
    results.push({
      shouldTrigger: true,
      message: `你工作挺久了，要不要休息一下？站起来活动活动 💺`,
      type: 'break',
      priority: 'low',
    });
  }

  // ── 4. 晚安提醒 ───────────────────────────────────
  if (hour === 22 && !state.sentReminders.includes(`sleep:${dayStr}`)) {
    results.push({
      shouldTrigger: true,
      message: `快22点了 ${state.name}，该准备休息了。晚安～ 🌙`,
      type: 'health',
      priority: 'low',
    });
  }

  // ── 5. 项目更新提醒 ───────────────────────────────
  if (hour === 17 && state.preferences.currentProjects.length > 0) {
    const projReminderKey = `project:${dayStr}`;
    if (!state.sentReminders.includes(projReminderKey)) {
      results.push({
        shouldTrigger: true,
        message: `快下班了，今天 ${state.preferences.currentProjects[0]} 的进展怎么样？`,
        type: 'project',
        priority: 'low',
      });
    }
  }

  // ── 6. 情境感知（基于最近对话）───────────────────
  // 例如：提到生病/累了 → 表达关心
  // 例如：提到某个项目进展 → 适时跟进
  // 这个需要 async loadWrenContext()，在 evaluateTrigger 里处理

  return results;
}

/**
 * 生成主动消息（带上下文）
 */
export async function generateCompanionMessage(
  state: CompanionState,
  trigger: TriggerResult,
): Promise<string> {
  // 如果已经有预设消息，直接返回
  if (trigger.message) return trigger.message;

  const now = new Date();
  const idleMs = now.getTime() - state.lastActive;
  const idleHours = Math.floor(idleMs / (1000 * 60 * 60));
  const idleMins = Math.floor((idleMs % (1000 * 60 * 60)) / (1000 * 60));

  // ── 基于上下文生成消息 ────────────────────────────
  const context = await loadWrenContext();

  switch (trigger.type) {
    case 'idle':
      if (idleHours >= 8) {
        return `嘿 ${state.name}，你好像离开很久了？有什么需要我帮忙的吗。`;
      }
      if (idleHours >= 4) {
        return `${state.name}，还在吗？今天过得怎么样？`;
      }
      return `（沉默 ${idleHours}h${idleMins}m）`;

    case 'break':
      if (context.recentEvents.length > 0) {
        return `你刚刚提到"${context.recentEvents[context.recentEvents.length - 1].substring(0, 30)}"... 有需要继续聊的吗？`;
      }
      return undefined;

    default:
      return undefined;
  }
}

// ── 伴侣评估（供 cron job 调用）────────────────────────────

export interface CompanionEvaluation {
  shouldSend: boolean;
  message: string | null;
  type: TriggerResult['type'] | null;
  priority: TriggerResult['priority'];
  reason: string;
}

export async function evaluateCompanion(): Promise<CompanionEvaluation> {
  const state = loadState();
  const now = new Date();
  const hour = now.getHours();

  // ── 频率限制：至少隔 4 小时才发主动消息 ──────────
  const minInterval = 4 * 60 * 60 * 1000;
  if (now.getTime() - state.lastCompanionMessage < minInterval) {
    return {
      shouldSend: false,
      message: null,
      type: null,
      priority: 'low',
      reason: '频率限制：距上次消息不足4小时',
    };
  }

  // ── 夜间静音（23:00 - 07:00）────────────────────
  if (hour < 7 || hour >= 23) {
    return {
      shouldSend: false,
      message: null,
      type: null,
      priority: 'low',
      reason: '夜间静音时段',
    };
  }

  // ── 非活跃时段检测 ────────────────────────────────
  // 如果不在活跃时段，降低优先级
  const isActiveHour = state.preferences.activeHours.includes(hour);
  if (!isActiveHour && now.getTime() - state.lastActive > 30 * 60 * 1000) {
    return {
      shouldSend: false,
      message: null,
      type: null,
      priority: 'low',
      reason: `非活跃时段 (${hour}h)`,
    };
  }

  // ── 触发检测 ──────────────────────────────────────
  const triggers = checkTriggers(state, now);
  
  // 只选最高优先级的触发
  const sorted = triggers
    .filter(t => t.shouldTrigger)
    .sort((a, b) => {
      const order = { high: 0, medium: 1, low: 2 };
      return order[a.priority] - order[b.priority];
    });

  if (sorted.length === 0) {
    return {
      shouldSend: false,
      message: null,
      type: null,
      priority: 'low',
      reason: '无触发条件',
    };
  }

  const top = sorted[0];
  const message = await generateCompanionMessage(state, top);

  if (!message) {
    return {
      shouldSend: false,
      message: null,
      type: top.type ?? null,
      priority: top.priority,
      reason: '无法生成消息内容',
    };
  }

  return {
    shouldSend: true,
    message,
    type: top.type ?? null,
    priority: top.priority,
    reason: `触发: ${top.type} (${top.priority})`,
  };
}

/**
 * 记录伴侣已发送消息（更新状态）
 */
export function markMessageSent(type: string): void {
  const state = loadState();
  const dayStr = new Date().toISOString().split('T')[0];
  state.lastCompanionMessage = Date.now();
  state.sentReminders = [
    ...state.sentReminders.filter(r => !r.endsWith(dayStr)), // 清理当天之前的记录
    `${type}:${dayStr}`,
  ];
  saveState(state);
}

/**
 * 更新最后活跃时间（由主 session 调用）
 */
export function touchActivity(): void {
  const state = loadState();
  const now = Date.now();
  const wasIdle = now - state.lastActive > 60 * 60 * 1000; // >1h idle
  state.lastActive = now;
  if (wasIdle) {
    state.lastCheckIn = now; // 重新活跃时重置 check-in
  }
  saveState(state);
}
