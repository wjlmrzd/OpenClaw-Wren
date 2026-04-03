# Claude Code 源码架构 vs OpenClaw 对比分析

> 来源：Claude Code 泄露源码 (2026-03-31) vs OpenClaw v0.2.0
> 分析时间：2026-04-03

---

## 📦 Claude Code 源码结构

```
src/
├── main.tsx              # CLI 入口 + REPL 引导 (4,683 行)
├── query.ts              # 核心 Agent 循环 (785KB，最大单文件)
├── QueryEngine.ts        # SDK/无头模式的查询生命周期引擎
├── Tool.ts               # Tool 接口定义 + buildTool 工厂
├── tools.ts              # Tool 注册和预设
├── commands.ts           # Slash 命令定义 (~25K 行)
├── context.ts            # 用户输入上下文处理
├── history.ts            # 会话历史管理
├── cost-tracker.ts       # API 成本实时追踪
├── commands/             # ~50 个 slash 命令实现
├── tools/                # ~40 个 Tool 实现
├── components/           # Ink UI 组件 (~140 个)
├── hooks/                # React hooks
├── services/             # 外部服务集成
├── screens/              # 全屏视图
└── buddy/                # 掌上宠物风格的伴侣系统
```

---

## 📦 OpenClaw 当前结构

```
dist/ (编译后)
├── agents/               # Agent 运行器 + 工具系统
│   ├── cli-runner/       # CLI 执行
│   ├── pi-embedded-runner/  # 插件嵌入式 Agent
│   ├── pi-embedded-helpers/
│   ├── tools/            # Tool 实现 (~30 个)
│   ├── auth-profiles/
│   ├── skills/           # Skill 管理
│   ├── context.js         # ⚠️ 单文件承担过多职责
│   ├── handlers.js        # 消息处理器
│   ├── compaction.js      # 上下文压缩
│   ├── model-selection.js
│   ├── tool-*.js          # 零散的工具定义
│   └── pi-embedded.js     # 核心 Agent 运行器
├── plugins/              # 插件系统
│   ├── runtime/
│   ├── loader.js
│   ├── registry.js
│   └── schema-validator.js
├── hooks/                # Hook 系统
├── memory/               # 记忆插件
├── routing/              # 消息路由
├── channels/             # 渠道集成
│   ├── telegram/
│   ├── feishu/
│   ├── discord/
│   ├── slack/
│   └── whatsapp/
├── providers/            # LLM Provider 抽象
├── cron/                 # Cron 调度
├── gateway/              # Gateway 服务
├── infra/                # 基础设施
└── config/               # 配置管理
```

---

## 🔍 逐维度对比分析

### 1. Agent 循环设计

| 维度 | Claude Code | OpenClaw |
|------|------------|----------|
| 核心循环位置 | `query.ts` (785KB) | `pi-embedded.js` + `handlers.js` |
| 查询引擎抽象 | `QueryEngine.ts` 独立 | 分散在 runner 里 |
| 生命周期钩子 | `QueryEngine` 托管 | `hooks/` 分散 |
| 重试/容错 | 内置于 loop | 部分在 runner |

**OpenClaw 问题**：`pi-embedded-runner` 的职责不清晰，既是 runner 又承担了部分 tool calling 逻辑。Claude Code 的 `QueryEngine` 抽离了"查询生命周期"，runner 只负责执行。

### 2. Tool 系统

| 维度 | Claude Code | OpenClaw |
|------|------------|----------|
| 工厂模式 | `buildTool` 工厂函数 | 零散定义 |
| Tool 数量 | ~40 个内置 | ~30 个内置 |
| Schema 定义 | `Tool.ts` 统一 | `*.schema.js` 分散 |
| 策略层 | `tool-policy.js` | 部分在 `tool-policy.js` |
| Tool 注册 | `tools.ts` 集中 | `openclaw-tools.js` 集中 |

**OpenClaw 优势**：已有 `tool-policy.js`、`tool-mutation.js` 等策略层，比 Claude Code 更安全。

**可借鉴**：统一 `buildTool` 工厂，让所有工具走同一套 schema 生成 + 策略检查流水线。

### 3. 上下文管理

| 维度 | Claude Code | OpenClaw |
|------|------------|----------|
| 上下文收集 | `context.ts` 独立 | `context.js` 单文件 |
| Token 预算 | 无显示追踪 | `context-window-guard.js` |
| 历史管理 | `history.ts` | session transcript |
| 成本追踪 | `cost-tracker.ts` | ❌ 无独立模块 |

**Claude Code 亮点**：`cost-tracker.ts` — 每个 Query 输出 token 消耗、API 调用费用。OpenClaw 目前没有独立成本追踪模块（只有 `usage.js`）。

### 4. 命令系统

| 维度 | Claude Code | OpenClaw |
|------|------------|----------|
| 命令数量 | ~50 个 slash commands | 少量内置 |
| 命令实现 | `commands/` 目录 | 分散在各处 |
| 用户自定义 | 无 | Skill 系统 |
| 动态注册 | `commands.ts` 集中 | skill 动态加载 |

**可借鉴**：Claude Code 的 slash commands 比 OpenClaw 更 CLI-native。可以为 OpenClaw CLI 命令（如 `/session`, `/skill`, `/model`）建立类似的集中注册表。

### 5. UI 层

| 维度 | Claude Code | OpenClaw |
|------|------------|----------|
| 渲染框架 | Ink (React for CLI) | ❌ 无 TUI |
| TUI 组件 | ~140 个 | 基础 terminal 输出 |
| 控制面板 | `screens/` 全屏 | Gateway UI (web) |

**OpenClaw 现状**：Gateway 提供 web 控制面板，Telegram/飞书等渠道原生 UI。Claude Code 的 TUI 更适合纯 CLI 场景，OpenClaw 多渠道策略不同。

### 6. 伴侣系统 (Claude Code 独有关键！)

Claude Code 在 `src/buddy/` 下有一个完整的"掌上宠物"伴侣系统——Tamagotchi 风格：
- 主动发送状态更新
- 在长时间无操作时主动提示
- 模拟"有存在感"的 AI 助手

**OpenClaw 对应**：Cron heartbeat 有类似功能，但没有"伴侣"人格化设计。

### 7. 插件系统

| 维度 | Claude Code | OpenClaw |
|------|------------|----------|
| 插件隔离 | ❌ 无（纯单体） | ✅ sandbox runner |
| 插件 SDK | ❌ 无 | `plugin-sdk/` |
| Hook 系统 | ❌ 无 | `hooks/` |
| 插件发现 | npm 包 | `clawdhub` + 本地路径 |

**OpenClaw 优势**：插件架构 + sandbox 隔离比 Claude Code 更安全、可扩展。

---

## 🎯 OpenClaw 可落地的优化项

### 高优先级（立即可做）

#### 1. 独立 Cost Tracker 模块
Claude Code 的 `cost-tracker.ts` 实时追踪每次 API 调用的费用。

**现状**：OpenClaw 只有 `usage.js` 被动记录，没有成本估算。

**落地**：
```
agents/cost-tracker.js
  - trackApiCall(provider, model, inputTokens, outputTokens)
  - getRunningCost()
  - getSessionCost()
  - formatCost() // 格式化输出
```

#### 2. 统一 buildTool 工厂
Claude Code 的 `Tool.ts` 提供一致的 tool 定义流水线。

**落地**：
```typescript
// agents/tools/tool-factory.js
function buildTool({ name, description, schema, handler, policy }) {
  // 1. schema 校验
  // 2. policy 检查
  // 3. handler 执行
  // 4. 结果格式化
}
```

#### 3. 提取 Context Budget 管理器
把 `context-window-guard.js` 升级为独立的 Context Manager。

**落地**：
```
agents/context/
  ├── budget.js      # Token 预算计算
  ├── window.js      # 上下文窗口管理
  ├── compaction.js  # 压缩策略
  └── cost-tracker.js # 成本追踪（新增）
```

### 中优先级（有价值但需投入）

#### 4. Companion 伴侣系统
借鉴 Claude Code 的 `buddy/` 设计，做一个轻量版。

**用途**：
- 长时间无操作时的主动提醒
- 训练/健康/工作节奏的温和提示
- 不只是 Cron 推送，而是有"人格"的主动交互

**落地**：Skill 格式封装，监听 session idle 状态。

#### 5. Query Engine 抽象
把 `pi-embedded-runner` 里的查询逻辑抽出来。

**落地**：
```
agents/query-engine.js
  - prepareContext()    // 收集上下文
  - executeQuery()      // 执行 LLM 调用
  - processToolCalls()  // 处理工具调用
  - handleResponse()    // 处理响应
  - compact()           // 触发压缩
```

### 低优先级（长期演进）

#### 6. CLI 命令注册表
参考 `commands.ts`，建立统一的 CLI 命令系统。

#### 7. 140 个 Ink UI 组件
不适用于 OpenClaw（多渠道架构），除非做纯 CLI 模式。

---

## ✅ 总结：OpenClaw 的核心优势已领先

Claude Code 泄露源码的最大价值不是"我们要抄它"，而是**验证了某些设计方向**：

| Claude Code 验证的方向 | OpenClaw 现状 |
|----------------------|--------------|
| 独立 Cost Tracking | ❌ 待补 |
| Tool 工厂模式 | ⚠️ 部分有 |
| Context Budget 管理 | ⚠️ 基础有 |
| Companion 伴侣系统 | ❌ 待补 |
| Query Engine 抽象 | ⚠️ Runner 内置 |
| 多渠道集成 | ✅ 领先 |
| 插件系统 + Sandbox | ✅ 领先 |
| Hook 系统 | ✅ 领先 |
| Skill 自定义生态 | ✅ 领先（ClawdHub）|

**结论**：OpenClaw 架构上比 Claude Code 更现代（多渠道、插件化、安全隔离）。主要差距在 **Agent 内部的精细化管理**（cost tracking、tool factory、context budget）。

---

*生成时间: 2026-04-03*
*来源: Claude Code 泄露源码分析 + OpenClaw v0.2.0 源码*
