# checkpoint-wrapper Skill

> ⚠️ **状态**: 实现中（engine wrapper 有 OpenClaw plugin 加载顺序问题）

## 问题背景

**核心问题**: OpenClaw 的 lossless-claw 在 `compact()` 时重建 DAG。如果在 tool call 之间触发 compaction（跨多工具的长任务），in-progress turn 的状态可能丢失。

**nanobot 的解法** (Python):
```python
# 每个 tool call 后自动 checkpoint
_checkpoint(payload)  # 保存到 session metadata

# 重启后恢复未完成的 turn
_restore_runtime_checkpoint(session)
```

## 架构差异

| 维度 | nanobot | OpenClaw |
|------|---------|---------|
| **存储** | JSONL 文件 | SQLite (lossless-claw) |
| **Checkpoint 时机** | 每个 tool call 后 | 无内置钩子 |
| **恢复机制** | session metadata + 游标 | 无 |
| **compact 影响** | JSONL append-only，更新的是 DAG 指针 | compact 重建 DAG |

## 技术限制

1. **Plugin 加载顺序**: workspace plugins 先于 global npm packages 加载。checkpoint-wrapper 注册 `checkpoint:` engine factory，但 lossless-claw 后加载时会覆盖它。
2. **无 session-save hook**: 无法在每个 tool call 后触发 checkpoint。
3. **lossless-claw 使用 SQLite**: checkpoint 需备份 DB 状态，而非 JSONL 文件。

## 替代方案

### 方案 A: 预 compaction 快照（已实现）

在 compact 前快照 SQLite DB：
```python
# 运行时机: cron 调度，每次 compact 前
import shutil, sqlite3, datetime

def pre_compaction_backup(db_path):
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup = db_path.parent / f"lcm_backup_{ts}.db"
    shutil.copy2(db_path, backup)
    # 保留最近 3 个备份
    clean_old_backups(db_path.parent, keep=3)
```

### 方案 B: 定期 DB 快照（cron）

每 4 小时备份一次 SQLite DB：
```json
{
  "schedule": "cron: 0 */4 * * *",
  "action": "python backup_lcm_db.py"
}
```

### 方案 C: 软实时 checkpoint（推荐方案，需 OpenClaw 支持）

在 OpenClaw 核心添加 `onTurnCheckpoint` hook：
- 在 `_save_turn` 中调用 `hooks.emit('turn-checkpoint', session)`
- checkpoint-wrapper 监听此 hook，备份 session state
- OpenClaw 团队 PR 待提交

## 文件清单

```
plugins-checkpoint-wrapper/
├── src/
│   ├── checkpoint-engine.ts   # CheckpointContextEngine (wrapper engine)
│   └── store/
│       └── checkpoint-store.ts # JSON 文件 checkpoint 持久化
├── index.ts                  # plugin 入口（需手动注册到 lossless-claw 之后）
└── package.json
```

## 已知问题

- `CheckpointContextEngine` 理论上可以工作，但无法通过 workspace plugin 注册顺序覆盖 lossless-claw
- 建议：直接修改 lossless-claw 源码添加 checkpoint 支持，或等待 OpenClaw 官方支持
