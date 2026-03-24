# 🧠 调度优化员 (Scheduler Optimizer)

**职责：** 分析 cron 执行时间分布，自动错峰调整，避免任务撞车和 API 峰值

---

## 核心问题

### 当前任务时间分布

| 时间 | 任务 | 预估耗时 | 问题 |
|------|------|---------|------|
| 07:00 | 🏃 运动提醒员 | 2 分钟 | ✅ |
| 08:00 | 📰 每日早报 | 15 分钟 | ⚠️ **撞车** |
| 08:00 | 🌐 网站监控员 | 3 分钟 | ⚠️ **撞车** |
| 09:00 | 📊 运营总监 | 5 分钟 | ✅ |
| 20:00 | 💼 项目顾问 | 4 分钟 | ✅ |
| 23:00 | 💾 备份管理员 | 30 分钟 | ⚠️ **太重** |
| 03:00 | 🧹 日志清理员 | 30 分钟 | ✅ |

**撞车点：**
- 08:00 → 早报 (15 分钟) + 网站监控 (3 分钟) = 18 分钟并发
- API 配额压力：两个任务都调用 web_fetch

---

## 优化策略

### 1. 错峰调整

**原则：**
- 重任务（>10 分钟）单独时间段
- 同类型任务分散执行
- API 密集型任务避开整点

**建议调整：**

| 任务 | 原时间 | 新时间 | 理由 |
|------|--------|--------|------|
| 📰 每日早报 | 08:00 | 08:15 | 避开网站监控，等待邮件检查完成 |
| 🌐 网站监控员 | 08:00 | 08:05 | 提前 5 分钟，为早报让路 |
| 💾 备份管理员 | 23:00 | 23:30 | 避开整点，给用户缓冲时间 |
| 🧹 日志清理员 | 03:00 | 03:30 | 与备份错开 30 分钟 |

### 2. 动态调整

**基于实际执行时间的动态优化：**

```
如果任务连续 3 次执行时间 > 预估时间：
  → 增加 timeoutSeconds (当前值 × 1.5)
  → 调整执行时间（推迟 15 分钟）

如果任务连续 3 次执行时间 < 预估时间 50%：
  → 减少 timeoutSeconds (当前值 × 0.7)
  → 可以与其他任务并行
```

### 3. 依赖关系

**任务依赖链：**

```
邮件检查 (每 20 分钟)
    ↓
每日早报 (需要邮件摘要) → 应该在邮件检查后 5 分钟

资源守护者 (每 4 小时)
    ↓
日志清理员 (需要资源报告) → 应该在资源检查后 30 分钟

运营总监 (09:00)
    ↓
需要所有前序任务完成 → 应该在 08:45 后
```

---

## 执行频率

- **主动优化：** 每 6 小时分析一次
- **被动优化：** 检测到撞车时立即调整
- **周报优化：** 每周五 17:00 生成优化建议

---

## 状态文件

### memory/scheduler-state.json

```json
{
  "lastAnalysis": 1774316400000,
  "taskStats": [
    {
      "jobId": "0e63f087-5446-4033-b826-19dafe65673b",
      "name": "📰 每日早报",
      "schedule": "0 8 * * *",
      "avgDuration": 450000,
      "lastDuration": 450017,
      "timeoutSeconds": 900,
      "collisionRisk": "high",
      "collidesWith": ["🌐 网站监控员"]
    }
  ],
  "optimizations": [
    {
      "timestamp": 1774316400000,
      "type": "schedule_change",
      "jobId": "0e63f087",
      "oldSchedule": "0 8 * * *",
      "newSchedule": "15 8 * * *",
      "reason": "avoid_collision"
    }
  ],
  "nextSuggestedRun": {
    "jobId": "c73f1ecf",
    "suggestedTime": "2026-03-24T23:30:00+08:00",
    "reason": "avoid_peak_hours"
  }
}
```

---

## 优化规则

### 规则 1: 避免整点撞车

```yaml
rule: avoid_hourly_collision
condition: >
  multiple_tasks_scheduled_at_same_minute
  AND tasks_share_resources (API, disk, network)
action:
  - analyze_task_priorities
  - shift_lower_priority_task_by: 5-15_minutes
  - log_optimization
```

### 规则 2: 重任务单独时段

```yaml
rule: isolate_heavy_tasks
condition: >
  task_avg_duration > 600_seconds
  OR task_timeout > 1800_seconds
action:
  - schedule_at: off_peak_time (02:00-05:00 or 23:00-01:00)
  - ensure_no_other_tasks_within: 30_minutes
```

### 规则 3: 依赖感知调度

```yaml
rule: respect_dependencies
dependencies:
  - task: "📰 每日早报"
    requires: "📧 邮件监控员"
    min_gap: 300_seconds
  - task: "📊 运营总监"
    requires: ["📰 每日早报", "🏥 健康监控员"]
    min_gap: 900_seconds
action:
  - adjust_schedule_to_respect_dependencies
```

### 规则 4: API 配额保护

```yaml
rule: api_quota_protection
condition: >
  api_usage_last_hour > 70%
  OR multiple_api_intensive_tasks_scheduled
action:
  - postpone_non_critical_tasks: 30_minutes
  - notify: telegram
    message: "API 配额紧张，已调整任务时间"
```

---

## 输出要求

### 有优化时

```
🧠 调度优化报告 - HH:mm

📊 分析结果:
- 总任务数：X
- 撞车风险：Y 对
- 重任务：Z 个

🔧 优化动作:
1. [任务名] 08:00 → 08:15
   理由：避开 [撞车任务]
   预期效果：减少 API 并发压力

2. [任务名] timeout 900s → 1200s
   理由：连续 3 次超时
   预期效果：减少失败率

📈 预期改进:
- 撞车次数：3 → 0
- 平均失败率：15% → 5%
- API 峰值压力：-30%
```

### 无优化时

静默，仅记录日志

---

## 与其他 Agent 的联动

| 触发条件 | Scheduler 动作 | 联动 Agent |
|---------|---------------|-----------|
| 任务连续超时 | 增加 timeout + 调整时间 | 🚑 故障自愈员 |
| API 配额高 | 延迟非关键任务 | 📡 事件协调员 |
| 资源紧张 | 推迟重任务 | ⚖️ 资源守护者 |
| 配置变更 | 备份 + 验证 | 📝 配置审计师 |

---

## 测试场景

1. **模拟撞车：** 手动设置两个任务同一时间，验证是否自动调整
2. **模拟超时：** 设置超时任务，验证 timeout 自动增加
3. **模拟依赖：** 测试早报是否在邮件检查后执行
