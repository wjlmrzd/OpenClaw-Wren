# OpenClaw-CN 配置自学笔记

> 学习时间：2026-04-01 | 版本：0.2.0 | 来源：config.get + docs/index.md + docs/hooks.md

---

## 一、架构概览

```
用户 (Telegram/飞书/...)
        │
        ▼
  ┌────────────────────────┐
  │       Gateway          │  ws://127.0.0.1:18789
  │  (单进程，长期运行)     │
  │                        │
  │  - 渠道连接管理         │
  │  - WebSocket 控制平面   │
  │  - 会话路由            │
  │  - Cron 调度           │
  └───────────┬────────────┘
              │
              ├─ Pi Agent (RPC)
              ├─ CLI (openclaw-cn ...)
              ├─ 浏览器控制 UI (18789)
              └─ 节点 (iOS/Android via WS + pairing)
```

**核心原则：**
- **一个 Gateway 进程** = 所有渠道 + 所有会话
- **workspace 隔离**：每个 agent 有独立的 workspace
- **按渠道/话题隔离会话**：同一个群的不同 topic 是独立会话

---

## 二、配置结构 (openclaw.json)

### 2.1 顶层字段一览

| 字段 | 用途 | Wren 的值 |
|------|------|-----------|
| `meta` | 版本/时间戳追踪 | 0.2.0, 2026-03-31 |
| `env` | 环境变量注入 | PaddleOCR API |
| `wizard` | 安装向导记录 | doctor, local |
| `logging` | 日志级别 | info |
| `browser` | 浏览器控制 | enabled |
| `auth` | 认证配置 | minimax + dashscope |
| `models` | 模型 providers | 2 个 (minimax, dashscope) |
| `agents` | Agent 默认配置 | 8 个模型, workspace |
| `tools` | 工具配置 | image, audio (whisper) |
| `commands` | 命令行 | native auto |
| `hooks` | 内部钩子 | session-memory, boot-md |
| `channels` | 渠道配置 | Telegram + 飞书 |
| `gateway` | Gateway 本身 | port 18789, loopback |
| `skills` | 技能安装 | npm |
| `plugins` | 插件 | telegram, feishu |

---

## 三、核心概念详解

### 3.1 模型 Providers (`models`)

**Wren 的配置：2 个 provider**

```json
"providers": {
  "minimax-coding-plan": {
    "baseUrl": "https://api.minimaxi.com/anthropic",
    "api": "anthropic-messages",        // ← Anthropic 兼容 API
    "apiKey": "sk-cp-...",               // MiniMax API Key
    "models": [
      {
        "id": "minimax-2.7",            // 模型 ID
        "input": ["text", "image"],      // 支持 text + image 输入
        "contextWindow": 128000,         // 128K token 上下文
        "maxTokens": 8192                // 单次最大输出
      }
    ]
  },
  "dashscope-coding-plan": {
    "baseUrl": "https://coding.dashscope.aliyuncs.com/v1",
    "api": "openai-completions",         // ← OpenAI 兼容 API
    "apiKey": "sk-sp-...",               // 阿里云 DashScope API Key
    "models": [                          // 7 个模型
      "qwen3.5-plus", "qwen3-coder-plus", "qwen3-coder-next",
      "glm-5", "glm-4.7", "kimi-k2.5", "minimax-m2.5"
    ]
  }
}
```

**模型分层策略：**

```
主模型 (minimax-2.7)
  └─ 通用对话、日常任务、主会话
  └─ 支持图片输入

备用模型 (glm-5)
  └─ 主模型失败时自动切换

图像分析 (qwen3.5-plus)
  └─ 所有 image 工具调用

任务专用模型
  └─ qwen3-coder-plus/next: 编码任务
  └─ glm-5/glm-4.7: 知识/分析任务
  └─ kimi-k2.5/minimax-m2.5: 备用
```

### 3.2 Agent 配置 (`agents.defaults`)

```json
"agents": {
  "defaults": {
    "model": {
      "primary": "minimax-coding-plan/minimax-2.7",
      "fallbacks": ["dashscope-coding-plan/glm-5"]
    },
    "imageModel": {
      "primary": "dashscope-coding-plan/qwen3.5-plus"
    },
    "workspace": "D:\\OpenClaw\\.openclaw\\workspace",
    "compaction": {
      "mode": "default",
      "memoryFlush": {
        "enabled": true,
        "softThresholdTokens": 4000   // ← 低水位压缩触发
      }
    },
    "maxConcurrent": 4,                // 主 agent 最大并发
    "subagents": { "maxConcurrent": 8 } // 子 agent 最大并发
  }
}
```

**关键理解：**
- `compaction` = 上下文窗口快满时自动压缩
- `memoryFlush.enabled: true` = 压缩时写入 `memory/YYYY-MM-DD.md`
- `softThresholdTokens: 4000` = 剩余 4000 tokens 时触发（保守策略）

### 3.3 渠道配置 (`channels`)

#### Telegram

```json
"telegram": {
  "name": "WrenBot",
  "dmPolicy": "allowlist",             // ← DM 只允许白名单用户
  "botToken": "8329757047:...",
  "groups": {
    "-1003866951105": {               // g-openclaw 群 ID
      "enabled": true,
      "topics": {                     // 开启的话题
        "31": { "enabled": true },
        "166": { "enabled": true }
      }
    }
  },
  "groupPolicy": "allowlist",         // ← 群组只在白名单
  "streamMode": "partial"             // ← 流式输出（草稿更新）
}
```

**Policy 类型：**
- `allowlist` = 只允许白名单（安全优先）
- `denylist` = 拒绝黑名单（开放）
- `pairing` = 需要配对（飞书 DM 用）

**Topic 配置注意点：**
- 当前配置**只有 2 个 topic**（31, 166）在 config 中
- 但系统实际运行了 **6 个 topic**（81, 19, 174, 4 等）
- **差距原因**：config 只记录了部分 topic，新 topic 被自动创建但未写入 config
- **结论**：config 中 topic 字段是"已知的 topic"，不是"全部 topic"

#### 飞书

```json
"feishu": {
  "defaultAccount": "main",
  "accounts": {
    "main": {
      "appId": "cli_a92bb7f3923a5ccb",
      "appSecret": "...",
      "botName": "OpenClaw",
      "dmPolicy": "pairing",           // ← DM 需要配对
      "groupPolicy": "allowlist",
      "defaultUser": "ou_a5c4938f3a1fb4354f765ff9c3fcc68c"  // Wren 的飞书 ID
    }
  }
}
```

### 3.4 内部钩子 (`hooks.internal`)

```json
"hooks": {
  "internal": {
    "enabled": true,
    "entries": {
      "session-memory": {
        "enabled": true   // ← 会话结束时写入 memory
      },
      "command-logger": {
        "enabled": true   // ← 记录命令执行日志
      },
      "boot-md": {
        "enabled": true   // ← 启动时读取 BOOTSTRAP.md
      }
    }
  }
}
```

**Boot-md 机制（重要）：**
- 如果 `BOOTSTRAP.md` 存在于 workspace，启动时会读取
- 用于首次启动或记忆丢失时恢复身份
- Wren 有完整的 `BOOTSTRAP.md` + `SOUL.md` + `USER.md` 系统

### 3.5 工具配置 (`tools`)

```json
"tools": {
  "media": {
    "image": {
      "enabled": true,
      "maxBytes": 10485760   // 10MB
    },
    "audio": {
      "enabled": true,
      "maxBytes": 20971520,  // 20MB
      "models": [
        {
          "type": "cli",
          "command": "whisper",  // ← 使用 whisper CLI 转录
          "args": ["--model", "base", "{{MediaPath}}"],
          "timeoutSeconds": 60
        }
      ]
    }
  }
}
```

**Wren 的媒体处理：**
- **图片**：直接上传到模型分析（10MB 限制）
- **音频**：通过 `whisper --model base` 转录为文字

### 3.6 Gateway 配置

```json
"gateway": {
  "port": 18789,
  "mode": "local",
  "bind": "loopback",          // ← 只监听本地（安全）
  "controlUi": {
    "enabled": true,
    "basePath": "/openclaw",   // http://localhost:18789/openclaw
    "allowInsecureAuth": false  // ← 需要 token 认证
  },
  "auth": {
    "mode": "token",
    "token": "fe42791f..."     // Gateway 控制 Token
  },
  "tailscale": { "mode": "off" }  // 未启用 Tailscale
}
```

---

## 四、会话模型 (Sessions)

### 4.1 会话 Key 格式

```
agent:main:main                          ← DM (主脑)
agent:main:telegram:group:-1003866951105 ← 群组主会话
agent:main:telegram:group:-1003866951105:topic:166  ← 话题会话
agent:main:cron:<jobId>                   ← Cron 任务会话
```

### 4.2 会话隔离规则

| 类型 | 隔离性 | 说明 |
|------|--------|------|
| DM | 共享主会话 | 同一个用户的多设备共享 |
| 群组主会话 | 隔离 | 每个群一个会话 |
| 话题 | 完全隔离 | topic ID 区分 |
| Cron | 独立 | 每个 job 一个会话 |

### 4.3 Wren 的会话分布

- **1 个主会话**：`agent:main:main`（DM）
- **g-openclaw 群**：6 个话题会话 + 1 个主会话
- **其他 2 个群**：各 2 个会话
- **Cron 会话**：21 个（21 个活跃任务）
- **总计**：~49 个会话

---

## 五、Cron 任务调度

### 5.1 调度机制

- Cron 任务在 **isolated 会话**中运行
- 每个任务有独立会话，不会污染主会话
- 支持 `agentTurn`（AI 执行）和 `systemEvent`（注入事件）

### 5.2 任务类型

```json
// Isolated agentTurn（推荐）
{
  "payload": {
    "kind": "agentTurn",
    "message": "执行任务描述",
    "model": "qwen3.5-plus",
    "timeoutSeconds": 300
  },
  "sessionTarget": "isolated",
  "delivery": { "mode": "announce" }  // ← 自动发送结果
}

// Main session systemEvent
{
  "payload": {
    "kind": "systemEvent",
    "text": "提醒文本"
  },
  "sessionTarget": "main",
  "delivery": { "mode": "deliver", "channel": "telegram" }
}
```

### 5.3 静默策略（由任务自身实现）

```
22:00 - 06:00 → 静默时段
  └─ 只发阻断性失败（不积压）
  └─ 非阻断性 → 累积到 06:00 摘要

06:00 - 22:00 → 活跃时段
  └─ 所有任务正常报告
```

---

## 六、Skills 技能系统

### 6.1 架构

- Skill = 包含 `SKILL.md` 的文件夹
- 触发条件：`description` 字段匹配用户请求
- 安装方式：`npm`（由 `skills.install.nodeManager` 指定）

### 6.2 Wren 已安装的 Skills

**Workspace 内置：**
- `deflate` — 智能上下文压缩
- `memory-tiering` — 三层记忆架构
- `context-budgeting` — 分区管理
- `engineering-knowledge` — 工程知识管理
- `code-review` — 代码评审
- `security-auditor` — 安全审计
- `clawteam` — 多 agent 协作
- `openclaw-backup` — 备份恢复
- `docker-essentials` — Docker 命令

**npm 全局安装：**
- 约 20+ 个 Channel-specific skills（Telegram、飞书、iMessage 等）

### 6.3 Skill vs 内置工具

| 维度 | Skill | 内置工具 |
|------|-------|----------|
| 加载 | 按需（匹配 description） | 始终可用 |
| 灵活性 | 高（自定义指令） | 固定 |
| 适用场景 | 复杂任务流 | 简单操作 |

---

## 七、配置缺失发现

### 7.1 Telegram Topic 配置不完整

**问题**：
```json
// config 中只有 2 个 topic
"topics": { "31": {...}, "166": {...} }

// 但系统实际运行 6 个 topic
// 81 (避风港), 19 (脚本插件), 174 (工程知识整理), 4 (主管)
```

**原因**：OpenClaw 会自动创建新 topic，但 config 中的 `topics` 只是"已知/手动配置的"。**不是 bug，是设计如此。**

**影响**：修改 topic 配置时需要手动更新 config。

### 7.2 环境变量注入

```json
"env": {
  "PADDLEOCR_OCR_API_URL": "${PADDLEOCR_OCR_API_URL}"
}
```

- `${VAR_NAME}` 语法 = 从 `.env` 文件注入
- `.env` 不在 workspace 中（在 `D:\OpenClaw\.openclaw\.env`）
- 敏感信息通过此机制注入，不写在 config 里

### 7.3 模型推理能力

当前所有模型的 `reasoning: false`：
```json
{
  "id": "minimax-2.7",
  "reasoning": false,  // ← 未开启推理模式
  "input": ["text", "image"]
}
```

如需开启：`reasoning: true`（需要模型支持）

---

## 八、Wren 专属配置解读

### 8.1 安全策略

```
DM: allowlist（只允许 Wren）
群组: allowlist（只允许 g-openclaw）
飞书: pairing（需配对）
绑定: loopback（不暴露外网）
Token 认证: 启用
```

**评价**：非常安全，符合 Wren 的"安全优先"偏好。

### 8.2 性能优化

```
- memoryFlush: 启用（保守 4000 token）
- maxConcurrent: 4（主会话）
- subagents.maxConcurrent: 8（子任务）
- compaction: default
```

**评价**：适合日常使用，不会过度压缩。

### 8.3 媒体配置

```
图片: 10MB 上限，模型分析
音频: 20MB 上限，whisper 转录
```

**评价**：满足基本需求，无视频支持。

---

## 九、自查清单

- [x] 理解架构（Gateway + 会话模型）
- [x] 理解 providers 和 models 的区别
- [x] 理解 agents.defaults 的作用
- [x] 理解 channels 的 DM/group/topic 策略
- [x] 理解 hooks 的三个入口
- [x] 理解 Cron 的 isolated vs main
- [x] 发现 Topic 配置差异（config vs 实际）
- [x] 理解 env 注入机制
- [x] 理解 skills 加载逻辑

---

## 十、待学习深化

- [ ] `commands.native` 和 `commands.nativeSkills: "auto"` 的具体行为
- [ ] `models.mode: "merge"` 的合并策略
- [ ] Canvas 和 Browser Control 的进阶用法
- [ ] 节点（iOS/Android）配对机制
- [ ] Webhooks 和外部触发
- [ ] Tailscale 远程访问配置

---

*笔记由 Wren 的 AI 助手于 2026-04-01 自动生成*
