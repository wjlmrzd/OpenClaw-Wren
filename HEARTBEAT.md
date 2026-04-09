# HEARTBEAT.md

> 参考自 nanobot (HKUDS) 的 HEARTBEAT 设计 — LLM 驱动的 skip/run 决策

## 决策规则（每次心跳先执行此判断）

**skip 条件（无操作）：**
- `memory/notification-state.json` 中无 `pending_review` 字段，或值为空
- 过去 30 分钟内有用户主动对话（系统繁忙）
- 深夜 23:00-07:00（除非有紧急事件）

**run 条件（有操作）：**
- `pending_review` 有值 → 执行 Micro-Review
- `memory/user_update_pending.md` 存在且非空 → 执行 USER 周更新

## 任务清单

### 1. Micro-Review 触发
文件：`memory/notification-state.json`
```json
{
  "pending_review": null   // 无 → skip
}
```
- 读取 `pending_review` 字段
- 若有值，生成 3 句 micro-review，输出到当前会话
- 执行后清除字段

### 2. USER 周更新
文件：`memory/user_update_pending.md`
- 若文件存在且非空，提炼关键更新写入 USER.md
- 执行后删除文件

### 3. 内存清理检查
- `memory/` 目录 > 200 个文件 → 触发 session_archiver 归档
- 单个 JSON state 文件 > 100KB → 精简

## 命令参考（手动触发）

| 命令 | 动作 |
|------|------|
| `SESSION_ARCHIVE` | 运行 session_archiver.py |
| `USER_WEEKLY_UPDATE` | 读取 user_update_pending.md 更新 USER.md |

---
**原则**：宁可不做事，不要乱做事。nanobot 的 skip/run 逻辑核心是：让 LLM（或此处规则）判断是否真的需要执行，而不是每次都执行。
