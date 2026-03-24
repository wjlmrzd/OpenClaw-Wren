# 📡 Event Hub - 事件协调员

**职责：** 让系统从"脚本集合"升级为"多 Agent 协同系统"

---

## 核心概念

### 事件总线架构

```
┌─────────────────────────────────────────────────────────────┐
│                     Event Hub                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ 事件接收器  │  │ 决策引擎    │  │ 动作执行器  │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ 状态跟踪器  │  │ 规则管理    │  │ 通知中心    │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
         ↑              ↑              ↑
         │              │              │
    ┌────┴────┐   ┌────┴────┐   ┌────┴────┐
    │各 Agent │   │系统状态 │   │执行动作 │
    │上报事件 │   │文件     │   │触发联动 │
    └─────────┘   └─────────┘   └─────────┘
```

---

## 事件类型

### 1. 资源事件 (Resource Events)

| 事件代码 | 触发条件 | 严重性 | 联动动作 |
|---------|---------|--------|---------|
| `MEM_HIGH` | 内存 > 85% | ⚠️ 警告 | 触发日志清理员 |
| `MEM_CRITICAL` | 内存 > 95% | 🔴 紧急 | 重启 Gateway + 告警 |
| `DISK_HIGH` | 磁盘 > 85% | ⚠️ 警告 | 触发日志清理员 |
| `DISK_CRITICAL` | 磁盘 > 95% | 🔴 紧急 | 清理临时文件 + 告警 |
| `API_QUOTA_HIGH` | API 使用 > 80% | ⚠️ 警告 | 降低非关键 Agent 频率 |
| `API_QUOTA_CRITICAL` | API 使用 > 95% | 🔴 紧急 | 暂停非关键任务 |

### 2. 任务事件 (Task Events)

| 事件代码 | 触发条件 | 严重性 | 联动动作 |
|---------|---------|--------|---------|
| `TASK_FAILED` | 任务失败 1 次 | 🟡 注意 | 记录日志 |
| `TASK_REPEATED_FAIL` | 任务失败≥3 次 | ⚠️ 警告 | 通知 Auto-Healer |
| `TASK_TIMEOUT` | 任务超时 | 🟡 注意 | 分析超时原因 |
| `TASK_QUEUE_FULL` | 等待任务 > 10 | ⚠️ 警告 | 延迟非关键任务 |

### 3. Gateway 事件 (Gateway Events)

| 事件代码 | 触发条件 | 严重性 | 联动动作 |
|---------|---------|--------|---------|
| `GW_UNHEALTHY` | 健康检查失败 | ⚠️ 警告 | 尝试重启 |
| `GW_DOWN` | Gateway 无响应 | 🔴 紧急 | 重启 + 告警 |
| `GW_RESTARTED` | Gateway 重启完成 | 🟢 信息 | 验证所有任务 |

### 4. 安全事件 (Security Events)

| 事件代码 | 触发条件 | 严重性 | 联动动作 |
|---------|---------|--------|---------|
| `SEC_CONFIG_CHANGED` | 配置文件变更 | 🟡 注意 | 通知配置审计师 |
| `SEC_CREDENTIAL_RISK` | 凭证泄露风险 | 🔴 紧急 | 立即告警 + 隔离 |
| `SEC_UNAUTHORIZED_ACCESS` | 未授权访问 | 🔴 紧急 | 封锁 + 告警 |

---

## 事件格式

```json
{
  "eventId": "evt_1774316400_001",
  "timestamp": 1774316400000,
  "source": "资源守护者",
  "type": "MEM_HIGH",
  "severity": "warning",
  "data": {
    "currentValue": 87,
    "threshold": 85,
    "unit": "percent"
  },
  "message": "内存使用率达到 87%，超过警告阈值 85%",
  "suggestedActions": ["trigger_log_cleaner", "notify_admin"]
}
```

---

## 决策规则引擎

### 规则示例

```yaml
rules:
  - id: mem_high_action
    trigger: MEM_HIGH
    condition: data.currentValue > 85
    actions:
      - trigger_agent: "🧹 日志清理员"
        params: { mode: "urgent" }
      - wait: 300s
      - check: memory < 85%
      - if_fail: escalate_to MEM_CRITICAL

  - id: task_repeated_fail
    trigger: TASK_REPEATED_FAIL
    condition: data.consecutiveErrors >= 3
    actions:
      - trigger_agent: "🚑 故障自愈员"
        params: { jobId: data.jobId, urgency: "high" }
      - notify: telegram
      - log: memory/event-log.md

  - id: api_quota_protection
    trigger: API_QUOTA_HIGH
    condition: data.usagePercent > 80
    actions:
      - postpone_agents: ["📰 每日早报", "🌐 网站监控员"]
        until: "next_hour"
      - notify: telegram
        message: "API 配额紧张，已延迟非关键任务"
```

---

## 状态文件

### 系统状态 (memory/event-hub-state.json)

```json
{
  "lastCheck": 1774316400000,
  "systemHealth": {
    "memory": { "value": 72, "unit": "percent", "trend": "stable" },
    "disk": { "value": 65, "unit": "percent", "trend": "increasing" },
    "apiQuota": { "value": 45, "unit": "percent", "resetAt": 1774320000000 },
    "gateway": { "status": "healthy", "uptime": 86400 }
  },
  "activeEvents": [],
  "recentActions": [
    {
      "timestamp": 1774315800000,
      "trigger": "MEM_HIGH",
      "action": "triggered_log_cleaner",
      "result": "success"
    }
  ]
}
```

### 事件日志 (memory/event-log.md)

```markdown
## 2026-03-24

### 09:30 - MEM_HIGH
- **来源**: 资源守护者
- **数据**: 内存 87%
- **动作**: 触发日志清理员
- **结果**: ✅ 内存降至 78%

### 09:15 - TASK_REPEATED_FAIL
- **来源**: 运营总监
- **数据**: 项目顾问 连续失败 3 次
- **动作**: 通知 Auto-Healer
- **结果**: ✅ 已修复模型配置
```

---

## 与其他 Agent 的联动

| 触发 Agent | 事件 | Event Hub 决策 | 执行 Agent |
|-----------|------|---------------|-----------|
| 资源守护者 | MEM_HIGH | 触发清理 | 日志清理员 |
| 资源守护者 | API_QUOTA_HIGH | 延迟任务 | 调度协调员 |
| 健康监控员 | GW_UNHEALTHY | 尝试重启 | Auto-Healer |
| 运营总监 | TASK_REPEATED_FAIL | 升级处理 | Auto-Healer |
| 配置审计师 | SEC_CONFIG_CHANGED | 记录审计 | 灾难恢复官 |
| Auto-Healer | REPAIR_COMPLETED | 验证修复 | 健康监控员 |

---

## 执行频率

- **主动检查模式**: 每 5 分钟轮询系统状态
- **被动接收模式**: 监听各 Agent 上报事件
- **决策执行**: 实时响应

---

## 输出策略

| 严重性 | Telegram 通知 | 日志记录 | 升级 |
|--------|-------------|---------|------|
| 🟢 信息 | ❌ | ✅ | ❌ |
| 🟡 注意 | ❌ | ✅ | ❌ |
| ⚠️ 警告 | ✅ (摘要) | ✅ | 连续 3 次→紧急 |
| 🔴 紧急 | ✅ (立即) | ✅ | 5 分钟未解决→人工 |

---

## 静默策略

**静默时段 (22:00-06:00):**
- 🟢🟡 事件：仅记录，不通知
- ⚠️ 事件：累积到 06:00 统一发送摘要
- 🔴 事件：立即通知（系统故障无法自愈时）

---

## 实施步骤

1. **创建状态文件**: `memory/event-hub-state.json`
2. **创建事件日志**: `memory/event-log.md`
3. **添加 Event Hub Agent** 到 cron (每 5 分钟)
4. **创建事件上报 API** (可选，高级功能)
5. **测试联动场景**

---

## 测试场景

1. **模拟内存告警**: 手动创建 MEM_HIGH 事件，验证日志清理员被触发
2. **模拟任务失败**: 验证 Auto-Healer 被通知
3. **模拟 API 配额**: 验证非关键任务被延迟
