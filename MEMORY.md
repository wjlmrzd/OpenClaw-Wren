# MEMORY.md - Long-Term Memory

> ⚠️ 保持精简，每次对话后更新。详细日志 → memory/YYYY-MM-DD.md，经验 → Obsidian knowledge/

---

## 🏠 系统基础

| 项目 | 值 |
|------|-----|
| openclaw-cn | **0.2.0** (2026-03-30 更新) |
| Node.js | v25.8.0 |
| Gateway | localhost:18789 |
| Workspace | D:\OpenClaw\.openclaw\workspace |
| 代理 | Clash Verge (127.0.0.1:7897) |
| logging | **warn** (2026-04-07 info→warn，减少日志量) |

**环境变量** (见 `.env`): TELEGRAM_BOT_TOKEN, FEISHU_APP_ID/SECRET, GATEWAY_AUTH_TOKEN, PADDLEOCR_*

---

## 📡 已配置渠道

### Telegram 群组主题 (Topic)
| Topic ID | 名称 | 用途 |
|----------|------|------|
| 166 | 总脑 | 主脑，日常中枢 |
| 19 | 脚本插件 | 脚本/插件讨论 |
| 31 | 新闻杂趣 | 新闻/趣味内容分享 |
| 81 | 避风港 | 闲聊/非正式交流 |
| 174 | 工程知识整理 | 工程知识整理 |
| 4 | 主管 | 监控/管理 |

- **Telegram**: `@WrenBot` (dmPolicy: allowlist)
- **飞书**: App ID `cli_a92bb7f3923a5ccb`，User ID `ou_a5c4938f3a1fb4354f765ff9c3fcc68c`
- **Obsidian**: E:\software\Obsidian\vault\

---

## 🧠 会话组织 (2026-04-01)

| Session | 角色 |
|---------|------|
| **166** | 主脑 — topic 主要会话对象，日常对话中枢 |

---

## 🤖 已安装插件 (plugins/)

### 📦 lossless-claw (2026-04-02 安装)
| 项目 | 值 |
|------|-----|
| ID | `lossless-claw` |
| 版本 | 0.5.2 |
| 来源 | `plugins-lossless-claw-enhanced/` |
| 类型 | DAG-based 对话压缩 + 工具集 |

**功能：** DAG 结构压缩对话历史，支持增量编译。提供以下工具：

| 工具 | 说明 |
|------|------|
| `lcm_grep` | 正则/全文搜索已压缩的历史记录 |
| `lcm_describe` | 查看摘要/Summary DAG 节点元数据 |
| `lcm_expand` | 将摘要展开回原始消息（支持 delegation） |
| `lcm_expand_query` | 子 Agent 委托式展开，回答聚焦问题 |
| `lcm_expansion_recursion_guard` | 防止展开循环 |

**配置 (openclaw.json):**
```json
"contextThreshold": 0.8,
"incrementalMaxDepth": 2,
"freshTailCount": 8,
"leafChunkTokens": 15000,
"summaryModel": "minimax-coding-plan/minimax-2.7",
"summaryProvider": "minimax-coding-plan"
```

> ⚠️ 已知：`lcm-expansion-recursion-guard.ts` 有 TypeScript 编译警告（不影响运行）
> ⚠️ 升级 openclaw 后需确认 `api.registerContextEngine` API 是否存在

### 📦 graph-memory (2026-04-02 安装)
| 项目 | 值 |
|------|-----|
| ID | `graph-memory` |
| 版本 | 1.5.6 |
| 来源 | `plugins-graph-memory/` |
| 作者 | adoresever |
| 类型 | 知识图谱记忆引擎 |

**功能：** 从对话提取三元组，FTS5+图遍历+PageRank 跨对话召回。提供以下工具：

| 工具 | 说明 |
|------|------|
| `gm_search` | 搜索知识图谱中的相关经验/技能/解决方案 |
| `gm_record` | 手动记录经验到图谱（节点+边） |
| `gm_stats` | 查看图谱统计：节点数、边数、社区数、PageRank Top |
| `gm_maintain` | 手动触发去重、PageRank 重算、社区检测 |

**配置 (openclaw.json):**
```json
"compactTurnCount": 10,
"recallMaxNodes": 4,
"recallMaxDepth": 1,
"dedupThreshold": 0.85,
"llm": { "model": "glm-5" },
"embedding": { "model": "text-embedding-v2" }
```

> ✅ 2026-04-08 更新：openclaw.json `plugins.entries.graph-memory.config` LLM 已配置为 GLM-5（百炼 API）
> ⚠️ 2026-04-03 的"已配置"记录实际未写入 openclaw.json，从未生效
> ✅ embedding 已配置 → 支持语义搜索 + 向量去重

---

## 🤖 已安装技能 (skills/)

### 记忆与压缩
| 技能 | 用途 | 路径 |
|------|------|------|
| deflate | 智能上下文压缩，Cornell-MapReduce 方法论，Zone 系统 | skills/deflate/ |
| memory-tiering | 热/温/冷三层记忆架构 | skills/memory-tiering/ |
| context-budgeting | 分区管理+预压缩 checkpointing | skills/context-budgeting/ |
| clawpressor | NLP summarization (Sumy) 压缩，60-80% token 节省 | skills/clawpressor/ |

> ⚠️ deflate 的 compaction 配置需手动写入 openclaw.json（已写入 memoryFlush.enabled=true）
> memory-tiering 需要 memory/hot/ 和 memory/warm/ 目录（已创建）

### Agent 协作
| 技能 | 用途 | 路径 |
|------|------|------|
| clawteam | 多 Agent swarm 协调（git worktree + tmux + 文件消息） | skills/clawteam/ |
| claw-kanban | AI Agent 看板编排（6 种 Agent，角色自动分配，实时监控） | skills/claw-kanban/ |
| sessions | 主/子 Agent 会话管理（spawn/send/status） | 内置 |
| task-dispatcher | 任务分发与协调 | skills/task-dispatcher/ |

### 工程与开发
| 技能 | 用途 | 路径 |
|------|------|------|
| code-review | 系统化代码审查（安全/性能/可维护/正确性） | skills/code-review/ |
| security-auditor | 安全审计（OWASP Top 10/认证/XSS/SQL注入） | skills/security-auditor/ |
| engineering-knowledge | 工程知识管理（CAD/自动化/架构/OCR） | skills/engineering-knowledge/ |
| docker-essentials | Docker 容器管理/镜像/Debug | skills/docker-essentials/ |
| github-actions-generator | GitHub Actions 工作流生成 | skills/github-actions-generator/ |
| github-cli | `gh` 命令行管理 Issue/PR/Run | skills/github-cli/ |
| batch-edit | 协同多文件编辑（原子性批量修改） | skills/batch-edit/ |

### 知识管理
| 技能 | 用途 | 路径 |
|------|------|------|
| Obsidian | Obsidian vault 操作（笔记/日记/知识） | skills/obsidian/ |
| verified-capability-evolver | 安全提升 Agent 能力（验证+回滚） | skills/verified-capability-evolver/ |
| fluid-memory | 记忆流管理 | skills/fluid-memory/ |

### 安全与维护
| 技能 | 用途 | 路径 |
|------|------|------|
| skill-security-auditor | AI Agent 技能安全审计/漏洞扫描 | skills/cs-skill-security-auditor/ |
| openclaw-backup | OpenClaw 数据备份/恢复 | skills/openclaw-backup/ |

### 工具类
| 技能 | 用途 | 路径 |
|------|------|------|
| paddleocr-text-recognition | 文字 OCR 识别 | skills/paddleocr-text-recognition/ |
| paddleocr-doc-parsing | 文档 OCR + 解析 | skills/paddleocr-doc-parsing/ |
| text-game-arcade-universe-v3 | 综合性 ASCII 文字游戏大厅 | skills/text-game-arcade-universe-v3/ |
| openai-whisper | 本地语音转文字 (faster-whisper + small 模型) | skills/openai-whisper/ |

- **Telegram**: `@WrenBot` (dmPolicy: allowlist)
- **飞书**: App ID `cli_a92bb7f3923a5ccb`，User ID `ou_a5c4938f3a1fb4354f765ff9c3fcc68c`
- **Obsidian**: E:\software\Obsidian\vault\

---

## 🤖 模型配置

### 💰 模型实际成本配置 (2026-04-07 更新)
> OpenClaw 成本追踪用（单位: USD/1M tokens）

| 模型 | Input | Output | 说明 |
|------|-------|--------|------|
| minimax-2.7 | $0.30 | $1.20 | MiniMax 官方定价 |
| qwen3.5-plus | $0.10 | $0.50 | 阶梯计费，取基准值 |
| qwen3-coder-plus | $0.65 | $3.25 | 编码模型，高输出 |
| qwen3-coder-next | $1.00 | $5.00 | 下一代编码模型 |
| glm-5 | $0.60 | $2.50 | 智谱 GLM-5（2026-02） |
| glm-4.7 | $0.45 | $1.80 | 智谱 GLM-4.7 |
| kimi-k2.5 | $0.60 | $2.50 | Moonshot K2.5 |

> ⚠️ 定价来源：OpenRouter/pricepertoken.com 公开数据，百炼阶梯计费取中间值参考

## 🏠 系统基础
|------|--------------|-----------|----------|
| minimax-2.7 | **204,800** | **131,072** | minimax-coding-plan |
| qwen3.5-plus | **262,144** | **32,768** | dashscope-coding-plan |
| qwen3-coder-plus | **998,400** | **65,536** | dashscope-coding-plan |
| qwen3-coder-next | **262,144** | **65,536** | dashscope-coding-plan |
| glm-5 | **200,000** | **16,384** | dashscope-coding-plan |
| glm-4.7 | **200,000** | **128,000** | dashscope-coding-plan |
| kimi-k2.5 | **262,144** | **32,000** | dashscope-coding-plan |
| minimax-m2.5 | **196,608** | **65,536** | dashscope-coding-plan |

> ⚠️ 2026-04-03 更新：所有模型的 contextWindow/maxTokens 均已更正为官方规格。旧值均为 128K/8K（错误）。

### 🖼️ 图像分析模型
- **默认使用**: `qwen3.5-plus` (dashscope-coding-plan/qwen3.5-plus)
- 所有 image 工具调用默认使用此模型

### 🎯 模型使用偏好 (Wren 设定)
| 任务类型 | 模型 | 说明 |
|---------|------|------|
| **日常编排** | minimax-2.7 | 高性价比，快速响应，$0.30/1M |
| **知识三元组** | glm-5 | 深度推理，可靠性高（2026-04-03 更新） |
| **代码生成** | minimax-2.7 | 204K context，131K output，强代码能力 |
| **文本处理** | glm-5 | 200K context，16K output，通用文本任务 |
| **图片处理** | qwen3.5-plus | 262K context，32K output，多模态 |

> 📖 详细路由参考：`Obsidian/知识/OpenClaw模型路由参考.md`
> 配置位置：`agents.defaults.model.primary` / `imageModel` / `plugins.graph-memory.config.llm`

### 📊 API 使用比例 (2026-04-03 优化)

**目标比例：MiniMax:Dashscope = 5:2 (71.4%:28.6%)**

| API | 月度调用预测 | 占比 | 任务数 |
|-----|-------------|------|--------|
| **MiniMax** | ~2000 次 | 71% | 32 |
| **Dashscope** | ~800 次 | 29% | 10 |

**模型分配策略：**
- **MiniMax (minimax-2.7)**: 高频监控任务、日常提醒
- **Dashscope GLM-5**: 文本生成、摘要、报告 (低频)
- **Dashscope Qwen**: 复杂分析、决策 (低频)

**关键调整：**
- 🧠 知识管理三元组: `*/6h` → `15 */6 * * *` (每6h整点+15分)，**使用 GLM-5 整理**
- 🚑 故障自愈员: → qwen3-coder-plus (复杂分析)

---

## 🛡️ Compaction Checkpoint 系统 (2026-04-09)

**目的**：解决 compaction 后 agent 状态损坏无法回滚的问题。

**实现**：直接修改 `plugins-lossless-claw-enhanced/` git repo (win4r/lossless-claw-enhanced)

**架构（v1 已完成）**：
- `_writeCheckpoint`：保存 contextItems + summaries + parentLinks + **messageLinks** → JSON
- `_runPassWithRollback`：包裹 leafPass/condensedPass，异常时自动 rollback
- `_cleanupCheckpoint`：成功后删除 checkpoint 文件
- `rollbackCheckpoint`：清空 context_items → 重插入原始 items → 重建 summary 关联

**关键修复（2026-04-09 完成）**：
- `insertContextItem`：`INSERT OR IGNORE` → `INSERT OR REPLACE`（rollback 可覆盖）
- `deleteContextItemsForConversation`：rollback 前清空脏状态
- `summaryMessageLinks`：checkpoint 保存 leaf-summary → source-messages 关联，rollback 重建

**Checkpoint 文件**：`~/.openclaw/agent-<id>/memory/lcm-checkpoints/{compactId}.json`

**Rollback 触发**：
- ✅ `_runPassWithRollback` 捕获异常 → 自动 rollback
- ⚠️ 无进展退出（tokens ≥ before）→ 暂不自动 rollback（future enhancement）
- ✅ 手动：`engine.rollbackCheckpoint(compactId)`

**Commit history**：
- `64ca587` — 初始 checkpoint + rollback 框架
- `c54a2de` — rollback 增强：clear before restore + message links

---

## ⚡ 关键教训 (must follow)

1. **飞书 DM 策略必须保持 `open`**（2026-04-09）：Wren 直接私聊机器人，不要配对流程。不要让它变回 pairing！
2. **配置修改前** → 查阅文档 → 说明变更 → 等确认 → 再重启
2. **MEMORY.md** 超过 20000 chars 会导致系统异常 → **必须保持精简！**
3. **不要等用户问"你还记得吗"** → 每次会话开始主动用 `gm_search` 搜相关上下文
4. **ClawHub 记忆类 skill（2026-04-07）**：elite-longterm-memory / neural-memory 都不值得装，依赖新插件/包
5. **Cron 超时** → 设为执行时间 × 1.5 以上
6. **PowerShell 编码** → 脚本保存为 UTF-8 with BOM，避免内联中文
7. **Git 备份** → 必须处理远程仓库不存在的情况（静默失败）
8. **Clash Verge TUN 模式** → 拦截 DNS 导致 SSRF 防护误判 → 已在 openclaw-cn 代码中 fix
9. **npm 全局包更新后** → 必须重启 Gateway
10. **网络问题排查顺序**：PowerShell curl → Node.js curl → OpenClaw logs → Gateway restart
11. **sessions.json 膨胀** → skillsSnapshot 含乱码中文 → 定期 trim (`trim-sessions.ps1`)
12. **Cron 消息中含中文** → 通过 exec 传给 PowerShell 时乱码 → 改用脚本文件引用
13. **Obsidian 核心目录** → **绝对不可删除**
14. **C 盘自动清理** → 资源守护者检测到 C 盘 >90% → **自动触发清理**

1. **配置修改前** → 查阅文档 → 说明变更 → 等确认 → 再重启
2. **MEMORY.md** 超过 20000 chars 会导致系统异常（如 API 超时）→ **必须保持精简！**
3. **Cron 超时** → 设为执行时间 × 1.5 以上
4. **PowerShell 编码** → 脚本保存为 UTF-8 with BOM，避免内联中文
5. **Git 备份** → 必须处理远程仓库不存在的情况（静默失败）
6. **Clash Verge TUN 模式** → 会拦截 DNS，导致 SSRF 防护误判 api.telegram.org → 在 openclaw-cn 代码中 fix
7. **npm 全局包更新后** → 必须重启 Gateway
8. **网络问题排查顺序**：PowerShell curl → Node.js curl → OpenClaw logs → Gateway restart
9. **sessions.json 膨胀** → skillsSnapshot 含乱码中文，导致加载变慢 → 定期 trim (`trim-sessions.ps1`)
10. **Cron 消息中含中文** → 通过 exec 传给 PowerShell 时乱码 → 改用脚本文件引用，避免内联命令
11. **Obsidian 核心目录** → 个人信息、使用手册、知识 → **绝对不可删除**
12. **C 盘自动清理** → 资源守护者检测到 C 盘 >90% → **自动触发清理**（无需确认，2026-04-03 Wren 设定）
13. **Cron announce channel** → `announce` 模式默认 whatsapp（未配置），导致 5 个任务反复失败 → 必须显式指定 `channel: telegram`

---

## 🗄️ Obsidian 配置快照 (2026-04-03 新建)

### Telegram SSRF 防护 (2026-03-25 初装，2026-04-01 重装)
- **文件**: `node_modules/openclaw-cn/dist/telegram/bot/delivery.js`
- **行 275, 348**: `fetchRemoteMedia(..., { ssrfPolicy: { allowedHostnames: ["api.telegram.org"] } })`
- ⚠️ openclaw 更新后会被覆盖，需每次检查并重新应用

### 代理问题 (2026-03-31)
- Dashscope/MiniMax via 代理返回 404 → 检查 Clash Verge 域名规则
- Telegram via 代理慢（6s+）→ 监控是否持续

### ClawTeam Windows 兼容性 (2026-04-01)

### 备份管理员已删除 (2026-04-01)
- git remote 不存在，每次 push 失败，状态长期 error
- 已从 cron 移除。如需备份功能，需重新配置 git remote

---

## 🗄️ 会话原文归档 (2026-04-09)
| 项目 | 值 |
|------|-----|
| 归档目录 | `memory/sessions/` |
| 归档脚本 | `scripts/session_archiver.py`（每4h触发） |
| 搜索脚本 | `python scripts/session_search.py -Query "关键词"` |
| 搜索入口 | AGENTS.md 双轨搜索：gm_search + session-search |

## 🗄️ 心跳微Review (2026-04-09)
HEARTBEAT.md 处理系统事件：
- `SESSION_ARCHIVE` → 归档最近4h会话
- `USER_WEEKLY_UPDATE` → 生成 USER.md 周更新草稿

pending_review 状态：其他 cron 完成重要任务后写字段，心跳读到触发 micro-review。

---

## 🗄️ nanobot 调研学习 (2026-04-09)

> 参考 HKUDS/nanobot (4K 行 Python，v0.1.5) 的设计

### 核心启发

**1. HEARTBEAT 机制（最值得借鉴）**
- nanobot 用 LLM 决定 skip/run，不只是读文件
- Phase1：读取 HEARTBEAT.md → LLM 工具调用判断是否有任务 → 返回 `skip` 或 `run`
- Phase2：仅当 Phase1 返回 `run` 才执行，避免无效调用
- 后评估：执行后 LLM 决定是否通知（`evaluate_response`）
- **行动**：已更新 HEARTBEAT.md，加入 skip/run 决策规则

**2. Dream 记忆系统（两阶段设计）**
- `history.jsonl`：append-only，游标管理，机器优先格式
- `Consolidator`：对话膨胀时总结最旧片段，追加到 history.jsonl
- `Dream`：cron 调度，慢而精确地处理 memory（读 history.jsonl + SOUL.md + USER.md + MEMORY.md）
- Surgical edit：不重写整个文件，只做最小必要修改
- GitStore 版本化：每次 Dream 改后可比较/回滚
- 命令：`/dream` `/dream-log <sha>` `/dream-restore <sha>`
- **行动**：创建 `scripts/nanobot-memory-cleanup.ps1` 清理旧文件，memory/ 144 文件

**3. 文件结构哲学**
```
workspace/
├── SOUL.md           # bot 的长期声音和沟通风格
├── USER.md           # 用户是谁，有什么偏好
└── memory/
    ├── MEMORY.md     # 项目事实、决策、持久上下文
    ├── history.jsonl # append-only 历史摘要
    ├── .cursor       # Consolidator 游标
    └── .dream_cursor # Dream 消费游标
```

**与当前系统的对比**：
- OpenClaw：lossless-claw (DAG压缩) + graph-memory (三元组) + deflate (Zone)
- nanobot：history.jsonl (游标) + Dream (两阶段编辑)
- nanobot 的 append-only 游标比 DAG 压缩更可靠、更简单

**4. 其他发现**
- nanobot 是 OpenClaw 的"教育版"——4K 行覆盖核心功能，代码完全可读
- HEARTBEAT 间隔 30min（比 OpenClaw 更频繁但更轻量）
- 所有 channel 插件化设计，代码分离清晰
- Provider registry 单点注册，新增 provider 仅需 2 步

---

## 🗄️ 自动归档系统 (2026-04-02)

| 项目 | 值 |
|------|-----|
| 脚本 | `scripts/memory-archiver.ps1` |
| 频率 | 每日 04:00 |
| 保留期 | 7 天 |
| 归档目录 | `memory/archive/` |
| Cron ID | `aa4d7fba` |

**归档规则：**
- 每日日志（YYYY-MM-DD.md）超过 7 天 → `memory/archive/`
- auto-healer/config-audit 旧报告 → `memory/archive/`
- cron-jobs.json > 30 条 → trim 到最近 30 条
- test-git.json > 5MB → 归档
- test-runner-state.json > 50 条 → trim
- `.memory-index*.json` → 归档

---

## 🗄️ Obsidian 配置快照 (2026-04-03 新建)
| 项目 | 值 |
|------|-----|
| 脚本 | `scripts/obsidian_config_backup.py` |
| 频率 | 每日 04:05 (Asia/Shanghai) |
| 输出 | `E:\software\Obsidian\vault\04_Archives\OpenClaw-Config-Snapshot.md` |
| Cron ID | `fa020812` |
| 内容 | openclaw.json + cron/jobs.json + skills + plugins + channels + workspace 文件 |
| 记忆备份 | `04_Archives/Memory-Backups/` (MEMORY.md + 所有 daily logs) |

> 用途：OpenClaw 重置后通过此笔记恢复所有配置。包含完整 JSON 和恢复步骤。

## 📅 当前活跃 Cron 任务 (36 个)

> ⚠️ 更新于 2026-04-10

### 🔴 需关注（error/stale）

| ID | 名称 | 状态 | 说明 |
|----|------|------|------|
| 791c995e | 📊 运营总监 | 🔴 已禁用 | 连续超时，已禁用 |
| 2bb2b058 | 💼 项目顾问 | 🟡 stale (22h) | 最后执行 20:00，昨天正常 |
| 53b6edc8 | 🛡️ 安全审计员 | 🔴 error | 超时 300s → 已改为 600s（2026-04-07） |

> ⚠️ `7677e68c` 已禁用（被 `ddd96cfb` 每6h 版本取代）
> ⚠️ `e430f8ec` / `b41843c3` 上次执行已恢复正常（MEMORY 未及时更新）

### ✅ 正常任务（按时间排列）

**深夜批处理 (00-06 AM)**

| ID | 名称 | 频率 | 说明 |
|----|------|------|------|
| ddd96cfb | 🧠 知识管理三元组 | `15 */6 * * *` | 每6h，知识管理主任务，GLM-5 整理 |
| 869b9a84 | 📄 工程文档解析员 | `30 2 * * *` | 凌晨文档 OCR |
| aa4d7fba | 📦 记忆归档员 | `0 4 * * *` | 凌晨归档 |
| fa020812 | Obsidian Config Snapshot | `5 4 * * *` | 凌晨配置快照 |
| 13f18a92 | 🧬 知识演化员 | `30 4 * * *` | 凌晨知识整理 |
| 98d9b2a8 | 🛠️ 每日维护员 | `35 4 * * *` | 凌晨维护 |
| 16c5208a | ⚙️ 配置优化员 | `38 4 * * *` | 凌晨配置优化 |
| af025901 | 🧹 日志清理员 | `42 4 * * *` | 凌晨日志清理 |
| b65e9a07 | 🚨 灾难恢复官 | `15 6 * * 0` | 周日 06:15 |
| f84bb934 | 🏃 跑步-周日 | `18 6 * * 0` | 周日 06:18 |
| 58540a34 | 🏃 运动提醒员 | `0 7 * * *` | 每天 07:00 |
| 3c5f825f | 🏃 跑步-周二 | `3 7 * * 2` | 周二 07:03 |
| e15879fd | 🏃 跑步-周四 | `8 7 * * 4` | 周四 07:08 |
| fae5e00a | 🏃 跑步-周六 | `13 7 * * 6` | 周六 07:13 |

**早间 (06-12 PM)**

| ID | 名称 | 频率 | 说明 |
|----|------|------|------|
| afd8aec9 | 🌅 早晨摘要 | `0 6 * * *` | 每天 06:00 |
| 22b950df | 🔍 系统自检员 | `0 4 * * *` | 每天 04:00 |
| b41843c3 | 🌐 网站监控员 | `12 8 * * *` | 每天 08:12 |
| b8665efb | 📰 每日信息汇总 | `10 9 * * *` | 每天 09:10 |
| 806f7f0b | 🧪 灾难演练员 | `5 10 * * 0` | 周日 10:05 |
| 53b6edc8 | 🛡️ 安全审计员 | `15 10 */2 * *` | 每2天10:15 (timeout 600s) |
| 2bb2b058 | 💼 项目顾问 | `0 20 * * *` | 每天 20:00 |

**高频监控 (每 2-4 小时)**

| ID | 名称 | 频率 | 说明 |
|----|------|------|------|
| ccb233d7 | 🚑 故障自愈员 | `17 */3 * * *` | 每3小时 |
| 93a63a28 | 💬 飞书下班提醒 | `0 18 * * 1-5` | 工作日 18:00 |
| 697b1445 | 📚 收藏夹同步 | `0 9 * * *` | 每天 09:00 |
| 0e63f087 | 📰 每日早报 | `0 8 * * *` | 每天 08:00 |
| 9f4f1914 | 🤖 伴侣检查员 | `8 */4 * * *` | 每4小时 |
| 3a1df011 | 📡 事件协调员 | `22 */6 * * *` | 每6小时 |
| c0849289 | 📦 会话归档员 | `0 */4 * * *` | 每4h归档会话到 memory/sessions/ |
| 4da456d5 | 📝 USER.md 周提炼 | `0 20 * * 0` | 周日 20:00 生成更新草稿 |
| e430f8ec | 💰 成本追踪员 | `0 */6 * * *` | 每6小时 |
| 7eb7f35e | 🔔 通知协调员 | `45 */3 * * *` | 每3小时 |
| b6bc413c | 🧠 调度优化员 | `15 */4 * * *` | 每4小时 |
| f920c2a2 | ⚖️ 资源守护者 | `33 */4 * * *` | 每4小时 |
| e4248abd | 🧪 回归测试员 | `35 */2 * * *` | 每2小时 |
| 92af6946 | 🏥 健康监控员 | `40 */4 * * *` | 每4小时 |
| 2b564e59 | 📝 配置审计师 | `50 */4 * * *` | 每4小时 |
| 4f5e3918 | 📧 邮件监控员 | `5 */4 * * *` | 每4小时 |
| fa18eb23 | 📊 每周训练回顾 | `0 20 * * 0` | 周日 20:00 |
| bb0ed170 | 💰 成本分析师 | `5 20 * * 0` | 周日 20:05 |
| 2428c991 | 📈 每周总结 | `0 17 * * 5` | 周五 17:00 |
| 7edd8ef6 | 🔍 Brave Search 配额追踪 | `0 */4 * * *` | 每4小时，>80%或超限发 Telegram 提醒 |

> 💡 完整实时列表：`openclaw cron list` | 调度优化员每 6 小时自动更新本表

---

## 📁 重要文件位置

- `scripts/brave-search-tracker.py` — Brave Search 月度用量追踪（阈值 950次，超过 80%/超限发 Telegram）
- `memory/events.log` — 结构化事件日志
- `memory/incident-log.md` — 事件升级记录
- `memory/system-mode-state.json` — 运行模式状态
- `memory/auto-healer-state.json` — 自愈状态
- `memory/notification-state.json` — 通知状态
- `scripts/` — 所有运维脚本
- `Obsidian vault/` — E:\software\Obsidian\vault\

---

## 🗂️ 归档索引 (详细日志)

| 日期 | 主题 |
|------|------|
| 2026-03-24 | 自治系统升级、情境静默、去重整理 |
| 2026-03-25 | 飞书集成、脱敏配置、Telegram SSRF |
| 2026-03-29 | 版本更新、技能安装 |
| 2026-03-31 | 工程知识系统、原子笔记、Cron 统一头部 |

> 详细记录见 `memory/` 目录或 Obsidian knowledge/

- **训练计划 (2026-04-03)**: 第一次训练数据提取已完成，训练计划将于 2026-06-29 结束
