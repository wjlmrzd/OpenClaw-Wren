# 记忆系统规范

**版本**: 1.0  
**最后更新**: 2026-03-26

---

## 记忆分层

### 1. 长期记忆 (Long-Term Memory)

**文件**: `MEMORY.md`

**内容**:
- 系统级决策和架构
- 重要事件和里程碑
- 经验教训和最佳实践
- 配置变更记录

**格式**:
```markdown
## YYYY-MM-DD: 标题

**事件**: 简短描述

### 关键信息
- 要点 1
- 要点 2

### 相关文件
- `path/to/file` - 用途

---
```

**维护规则**:
- 每月回顾一次，归档过时内容
- 保持条目简洁，不超过 50 行
- 使用统一标签系统

---

### 2. 每日记忆 (Daily Memory)

**文件**: `memory/YYYY-MM-DD.md`

**内容**:
- 当日对话要点
- 临时决策和上下文
- 待办事项和跟进

**格式**:
```markdown
# YYYY-MM-DD 记忆日志

## HH:MM - 标题

**类型**: 教导/决策/问题/完成

**内容**: 详细记录

**行动**: 已执行/待执行

---
```

**维护规则**:
- 保留最近 30 天
- 30 天后归档到 `memory/archive/`
- 重要内容提炼到 MEMORY.md

---

### 3. 任务记忆 (Task Memory)

**文件**:
- `memory/task-<name>-state.json` - 当前状态
- `memory/task-<name>-log.md` - 执行日志

**内容**:
- 任务进度和状态
- 执行历史和问题
- 决策记录

**state.json 格式**:
```json
{
  "taskId": "unique-id",
  "taskName": "任务名称",
  "status": "running|paused|completed|failed",
  "progress": 0-100,
  "startedAt": "ISO-8601",
  "lastUpdated": "ISO-8601",
  "nextAction": "下一步行动",
  "blockers": [],
  "notes": "关键备注"
}
```

**维护规则**:
- 任务完成后归档
- 保留最近 10 个已完成任务

---

### 4. 事件记忆 (Event Memory)

**文件**:
- `memory/event-log.md` - 事件时间线
- `memory/incident-log.md` - 故障记录

**内容**:
- 系统事件和告警
- 故障和恢复过程
- 性能指标

**格式**:
```markdown
## YYYY-MM-DD HH:mm - 事件代码

**来源**: Agent/系统名称
**严重性**: info/warning/critical/emergency
**描述**: 事件描述
**动作**: 采取的行动
**结果**: 解决状态
```

---

## 索引系统

**文件**: `memory/.memory-index.json`

**用途**:
- 快速定位记忆条目
- 标签搜索
- 重要性分级

**更新时机**:
- 新增 MEMORY.md 条目时
- 每日回顾时

---

## 清理策略

### 自动清理 (Cron)

**每天 03:00** 执行:

1. **归档 30 天前的每日记忆**
   - 源: `memory/2026-02-*.md`
   - 目标: `memory/archive/`

2. **压缩大日志文件**
   - 超过 1MB 的日志 → 压缩为 .zip

3. **清理临时状态文件**
   - 已完成的任务状态 → 归档

### 手动清理

**每月 1 日**:
- 回顾 MEMORY.md，归档过时条目
- 更新记忆索引
- 检查 archive 目录大小

---

## 使用指南

### 何时写入哪个文件

| 场景 | 目标文件 | 示例 |
|-----|---------|------|
| 系统架构决策 | MEMORY.md | 模型策略上线 |
| 配置变更 | MEMORY.md | 环境变量迁移 |
| Bug 修复 | MEMORY.md | SSRF 修复 |
| 当日对话 | memory/YYYY-MM-DD.md | 用户教导 |
| 任务进度 | task-*-state.json | 中期优化 |
| 系统告警 | event-log.md | Gateway 重启 |

### 记忆检索优先级

1. **任务相关** → task-*-state.json
2. **近期对话** → memory/YYYY-MM-DD.md
3. **系统决策** → MEMORY.md
4. **历史事件** → event-log.md
5. **全量搜索** → .memory-index.json

---

## 优化检查清单

- [ ] 无重复记录（同一事件不在多个文件重复）
- [ ] 文件大小合理（单个文件 < 100KB）
- [ ] 索引及时更新
- [ ] 过期内容已归档
- [ ] 敏感信息已脱敏
