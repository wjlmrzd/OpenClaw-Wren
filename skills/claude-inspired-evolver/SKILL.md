# Claude Inspired Evolver

借鉴 Claude Code 泄露源码中的三个核心设计，对 OpenClaw 进行增强。

## 来源

- Claude Code 源码泄露事件：2026-03-31，Chaofan Shou 发现 npm 包中包含 60MB sourcemap 文件，暴露完整 TypeScript 源码
- 分析报告：`docs/claude-code-vs-openclaw-architecture.md`

## 包含组件

### 1. 💰 Cost Tracker（成本追踪器）

**来源灵感**：`Claude Code` 的 `cost-tracker.ts`

**功能**：
- 记录每次 LLM 调用的 token 消耗和美元费用
- 按 session 维护运行成本
- 持久化存储（`memory/cost-tracker/store.json`）
- 格式化报告（Markdown 格式，AI 可读）

**文件**：`src/cost-tracker/`
- `pricing.ts` — 模型定价表（Anthropic/OpenAI/DashScope/MiniMax）
- `index.ts` — 核心追踪器

**使用**：
```
# 记录一次调用
trackCall({ sessionKey, modelId, provider, usage })

# 查询报告
formatCostReport({ sessionKey, includeDetails })

# 获取摘要
getCostSummary()
```

**已知模型定价**：
| 模型 | Input ($/1M) | Output ($/1M) |
|------|-------------|--------------|
| Claude Opus 4.5 | $15 | $75 |
| Claude Sonnet 4.5 | $3 | $15 |
| MiniMax 2.7 | 🆓 | 🆓 |
| Qwen3.5-Plus | $0.2 | $0.6 |

### 2. 🔧 Tool Factory（工具工厂）

**来源灵感**：`Claude Code` 的 `Tool.ts` buildTool 工厂模式

**设计原则**：
1. Schema 校验内嵌（TypeBox + JSON Schema）
2. Policy 检查层（allow/deny/require_param）
3. 统一错误处理（不会因为单个 tool 崩溃影响全局）
4. 标准化结果格式（success/content/error/metadata）

**文件**：`src/tool-factory/index.ts`

**使用示例**：
```typescript
import { buildTool, stringEnum, CommonSchemas } from './tool-factory';

const costTool = buildTool({
  name: 'cost-report',
  description: '查看当前 API 使用成本',
  schema: Type.Object({
    sessionKey: CommonSchemas.sessionKey,
    includeDetails: Type.Optional(Type.Boolean()),
  }),
  policy: [],
  handler: async (params, ctx) => {
    const report = formatCostReport(params);
    return { success: true, content: report };
  }
});
```

**核心 API**：
- `buildTool()` — 创建标准化 Tool
- `stringEnum()` / `optionalStringEnum()` — 枚举类型辅助
- `CommonSchemas` — 常用 schema 预设
- `checkPolicy()` — 策略检查引擎
- `jsonResult()` / `errorResult()` — 结果格式化

### 3. 🤖 Companion（伴侣系统）

**来源灵感**：`Claude Code` 的 `buddy/` Tamagotchi 风格伴侣

**设计目标**：
- 主动在有意义的时候说话，不凑数
- 温暖的、关心的、不过度打扰的个性
- 情境感知（了解当前项目、训练计划等）
- 记忆 Wren 的偏好和行为模式

**文件**：`src/companion/index.ts`

**触发类型**：
| 类型 | 触发条件 | 示例消息 |
|------|---------|---------|
| `idle` | 超过 3h 无操作 | "嘿 Wren，你好像离开很久了？" |
| `exercise` | 早 7 点（运动日） | "今天是运动日吗？🏃" |
| `break` | 连续工作 >2h 无休息 | "你工作挺久了，要不要休息一下？" |
| `sleep` | 晚 22 点 | "快22点了，该准备休息了 🌙" |
| `project` | 下午 5 点 | "今天项目进展怎么样？" |

**频率控制**：
- 主动消息至少间隔 **4 小时**
- 夜间静音：23:00 - 07:00 不发消息
- 每天每类型只发一次（去重）

**状态存储**：`memory/companion/state.json`

## 部署方式

三个组件均为**纯工具库**（TypeScript），可以被 OpenClaw 的 Skill 系统或 cron job 调用：

```
skills/claude-inspired-evolver/
├── SKILL.md                    # 本文件
├── src/
│   ├── cost-tracker/
│   │   ├── pricing.ts         # 定价表
│   │   └── index.ts           # 追踪器核心
│   ├── tool-factory/
│   │   └── index.ts           # 工厂 + 策略引擎
│   └── companion/
│       └── index.ts           # 伴侣系统
```

## 更新日志

- **2026-04-03**: 初始创建。参考 Claude Code 泄露源码 (2026-03-31)。
