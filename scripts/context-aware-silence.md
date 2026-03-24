# 🔕 情境感知静默 (Context-Aware Silence)

**目标：** 在合适的时间发送合适的通知，避免打扰用户

---

## 核心原则

### 1. 时间感知

| 时段 | 时间 | 通知策略 |
|------|------|---------|
| 🌅 早晨 | 06:00-09:00 | 正常通知（可发送日报/提醒） |
| 🌞 工作时间 | 09:00-12:00, 14:00-18:00 | 正常通知（可发送任务报告） |
| 🌆 傍晚 | 18:00-22:00 | 降级通知（仅警告/紧急） |
| 🌙 深夜 | 22:00-06:00 | 静默（仅紧急告警） |

### 2. 严重性分级

| 级别 | 图标 | 定义 | 通知策略 |
|------|------|------|---------|
| 🟢 信息 | ℹ️ | 日常报告、状态更新 | 仅记录日志，不通知 |
| 🟡 注意 | ⚠️ | 轻微异常、可自愈问题 | 工作时间通知，静默时段累积 |
| 🔴 警告 | 🚨 | 需要关注的问题 | 非静默时段立即通知 |
| 🔴🔴 紧急 | 🆘 | 系统故障、数据丢失风险 | **任何时段立即通知** |

### 3. 紧急事件定义

**仅在静默时段 (22:00-06:00) 发送通知：**

1. **系统故障**
   - Gateway 无法启动/重启失败
   - 内存使用率 > 95%
   - 磁盘使用率 > 95%

2. **安全事件**
   - 配置被未授权修改
   - 凭证泄露风险
   - 未授权访问尝试

3. **连续失败**
   - 关键任务连续失败 ≥ 5 次
   - Auto-Healer 修复失败 ≥ 3 次

4. **资源耗尽**
   - API 配额即将用尽 (< 5%)
   - 日志文件 > 1GB

---

## 实现方式

### 方式 1: Agent 内置逻辑（推荐）

每个 Agent 在发送通知前检查：

```javascript
// 伪代码示例
function shouldNotify(severity, currentHour) {
    const silentHours = { start: 22, end: 6 };
    const isSilent = currentHour >= silentHours.start || currentHour < silentHours.end;
    
    if (!isSilent) return true;  // 非静默时段，全部通知
    
    // 静默时段，仅紧急事件
    return severity === 'critical' || severity === 'emergency';
}
```

### 方式 2: 统一通知网关

创建 `scripts/notification-gateway.ps1`：

```powershell
function Send-SmartNotification {
    param(
        [string]$Message,
        [string]$Severity = "info",  # info, warning, critical, emergency
        [string]$Channel = "telegram",
        [string]$Target = "8542040756"
    )
    
    $hour = (Get-Date).Hour
    $isSilent = ($hour -ge 22 -or $hour -lt 6)
    
    # 静默时段策略
    if ($isSilent) {
        if ($severity -eq "info") {
            # 信息类：仅记录，不通知
            Write-Log $Message
            return
        }
        elseif ($severity -eq "warning") {
            # 警告类：累积到早晨统一发送
            Add-ToMorningDigest $Message
            return
        }
        # critical/emergency：立即通知
    }
    
    # 发送通知
    Send-Telegram -To $Target -Message $Message
}
```

### 方式 3: Cron 调度优化

在 Scheduler Optimizer 中集成：

```javascript
// 调整任务执行时间避开静默时段
if (task.severity === "info" && isSilentHour(task.schedule)) {
    rescheduleTo(task, "09:00");  // 推迟到工作时间
}
```

---

## 通知类型矩阵

| 通知类型 | 工作时间 | 傍晚 | 深夜 | 早晨 |
|---------|---------|------|------|------|
| 📰 每日早报 | ✅ 08:15 发送 | - | - | - |
| 📊 运营报告 | ✅ 09:00 发送 | - | - | - |
| 📈 每周总结 | ✅ 周五 17:00 | - | - | - |
| 🚨 紧急告警 | ✅ 立即 | ✅ 立即 | ✅ 立即 | ✅ 立即 |
| ⚠️ 任务失败 | ✅ 立即 | ⚠️ 累积 | ❌ 静默 | ✅ 发送摘要 |
| ℹ️ 状态更新 | ✅ 记录 | ✅ 记录 | ✅ 记录 | ✅ 记录 |
| 🧪 测试失败 | ✅ 立即 | ⚠️ 累积 | ❌ 静默 | ✅ 发送摘要 |

---

## 早晨摘要机制

**触发时间：** 06:00（静默时段结束后）

**内容：**
```
🌅 早晨摘要 (06:00)

📊 夜间概览:
- 系统状态：✅ 正常
- 任务执行：15 成功 / 2 失败
- 资源使用：内存 65%, 磁盘 45%

⚠️ 夜间警告 (2 条):
1. 03:15 - 日志清理员 执行超时 (已自动修复)
2. 04:30 - API 配额使用 > 80% (已调整)

📋 今日关注:
- 备份管理员 连续失败 2 次，需关注
- API 配额剩余 35%，预计可用 2 天
```

---

## 状态文件

### memory/notification-state.json

```json
{
  "currentMode": "work_hours",  // work_hours, evening, silent
  "lastModeChange": 1774316400000,
  "silentDigest": {
    "enabled": true,
    "scheduledTime": "0 6 * * *",
    "pendingMessages": [
      {
        "timestamp": 1774308000000,
        "severity": "warning",
        "source": "Auto-Healer",
        "message": "任务失败已自动修复"
      }
    ]
  },
  "statistics": {
    "today": {
      "sent": 5,
      "suppressed": 12,
      "queued": 2
    },
    "thisWeek": {
      "sent": 35,
      "suppressed": 89,
      "queued": 8
    }
  },
  "overrides": {
    "emergencyContacts": ["8542040756"],
    "alwaysNotifySources": ["🏥 健康监控员", "🚨 灾难恢复官"]
  }
}
```

---

## 配置示例

### openclaw.json 通知配置

```json
{
  "notifications": {
    "telegram": {
      "enabled": true,
      "target": "8542040756",
      "silentHours": {
        "start": 22,
        "end": 6,
        "timezone": "Asia/Shanghai"
      },
      "severityFilter": {
        "workHours": ["info", "warning", "critical", "emergency"],
        "evening": ["warning", "critical", "emergency"],
        "silent": ["critical", "emergency"]
      },
      "digest": {
        "enabled": true,
        "schedule": "0 6 * * *",
        "includeSuppressed": true
      }
    }
  }
}
```

---

## 实施步骤

### 阶段 1: 基础框架 (已完成)
- [x] 定义静默时段策略
- [x] 创建通知状态文件
- [x] 文档化紧急事件定义

### 阶段 2: Agent 集成 (进行中)
- [ ] 更新 Auto-Healer 集成静默检查
- [ ] 更新 Event Hub 集成静默检查
- [ ] 更新 Scheduler Optimizer 集成静默检查

### 阶段 3: 早晨摘要 (待完成)
- [ ] 创建早晨摘要 Agent
- [ ] 实现夜间消息累积
- [ ] 测试摘要生成

### 阶段 4: 优化迭代 (持续)
- [ ] 根据用户反馈调整策略
- [ ] 添加更多情境维度（日历、位置等）
- [ ] 机器学习优化通知时机

---

## 测试场景

### 场景 1: 工作时间任务失败
- **时间：** 10:00
- **事件：** 项目顾问执行失败
- **预期：** 立即发送 Telegram 通知

### 场景 2: 深夜任务失败
- **时间：** 03:00
- **事件：** 日志清理员执行失败（已自动修复）
- **预期：** 不发送通知，累积到早晨摘要

### 场景 3: 深夜 Gateway 故障
- **时间：** 02:00
- **事件：** Gateway 无法启动
- **预期：** 立即发送紧急通知（紧急事件例外）

### 场景 4: 傍晚 API 配额告警
- **时间：** 20:00
- **事件：** API 使用率 > 80%
- **预期：** 发送降级通知（包含在晚间摘要中）

---

## 成功标准

- [ ] 静默时段 (22:00-06:00) 无普通通知
- [ ] 紧急事件任何时段立即通知
- [ ] 早晨摘要包含夜间重要事件
- [ ] 用户满意度提升（主观评估）
- [ ] 通知点击率提升（可量化）

---

*文档版本：1.0*  
*最后更新：2026-03-24*
