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

**环境变量** (见 `.env`): TELEGRAM_BOT_TOKEN, FEISHU_APP_ID/SECRET, GATEWAY_TOKENS, PADDLEOCR_*

---

## 📡 已配置渠道

- **Telegram**: `@WrenBot` (dmPolicy: allowlist)
- **飞书**: App ID `cli_a92bb7f3923a5ccb`，User ID `ou_a5c4938f3a1fb4354f765ff9c3fcc68c`
- **Obsidian**: E:\software\Obsidian\vault\

---

## 🤖 模型配置

| 模型 | Provider | 用途 |
|------|----------|------|
| minimax-2.7 | minimax-coding-plan | 主模型 |
| glm-5 | dashscope-coding-plan | 备用/分析 |
| qwen3.5-plus | dashscope-coding-plan | 知识笔记 |
| qwen3-coder-plus | dashscope-coding-plan | 代码/结构 |
| kimi-k2.5, glm-4.7, minimax-m2.5, qwen3-coder-next | dashscope | 备用 |

---

## ⚡ 关键教训 (must follow)

1. **配置修改前** → 查阅文档 → 说明变更 → 等确认 → 再重启
2. **MEMORY.md** 超过 20000 chars 会导致系统异常（如 API 超时）→ **必须保持精简！**
3. **Cron 超时** → 设为执行时间 × 1.5 以上
4. **PowerShell 编码** → 脚本保存为 UTF-8 with BOM，避免内联中文
5. **Git 备份** → 必须处理远程仓库不存在的情况（静默失败）
6. **Clash Verge TUN 模式** → 会拦截 DNS，导致 SSRF 防护误判 api.telegram.org → 在 openclaw-cn 代码中 fix
7. **npm 全局包更新后** → 必须重启 Gateway
8. **网络问题排查顺序**：PowerShell curl → Node.js curl → OpenClaw logs → Gateway restart

---

## 🔧 已知修复（避免重蹈覆辙）

### Telegram SSRF 防护 (2026-03-25)
- **文件**: `node_modules/openclaw-cn/dist/telegram/bot/delivery.js`
- **行 275, 348**: `fetchRemoteMedia(url, { ssrfPolicy: { allowedHostnames: ["api.telegram.org"] } })`
- OpenClaw 更新后需重查

### 代理问题 (2026-03-31)
- Dashscope/MiniMax via 代理返回 404 → 检查 Clash Verge 域名规则
- Telegram via 代理慢（6s+）→ 监控是否持续

---

## 📅 当前活跃 Cron 任务 (25 个)

| ID | 名称 | 频率 | 超时 |
|----|------|------|------|
| 93a63a28-... | 💬 飞书下班提醒 | 工作日 18:00 | 60s |
| 5eb5b368-... | 🧠 知识整理员 | 每天 02:00 | 300s |
| 869b9a84-... | 📄 工程文档解析员 | 每天 02:30 | 300s |
| e4248abd-... | 🧪 回归测试员 | 每 30 分钟 | 120s |
| afd8aec9-... | 🌅 早晨摘要 | 每天 06:00 | 180s |
| 58540a34-... | 🏃 运动提醒员 | 每天 07:00 | 180s |
| 0e63f087-... | 📰 每日早报 | 每天 08:15 | 600s |
| 22b950df-... | 🔍 系统自检员 | 每天 04:00 | 180s |
| 7eb7f35e-... | 🔔 通知协调员 | 每 30 分钟 | 60s |
| 其他... | (见 openclaw cron list) | | |

---

## 📁 重要文件位置

- `.env` — 敏感环境变量（勿提交）
- `.env.example` — 环境变量模板
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
