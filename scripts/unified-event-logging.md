# 统一事件日志格式规范

## 日志文件

### memory/events.log (主日志)

**格式:**
```
[YYYY-MM-DD HH:mm:ss] [SEVERITY] [SOURCE] message | key=value
```

**严重性级别:**
- `INFO` - 普通信息
- `SUCCESS` - 执行成功
- `WARNING` - 警告
- `ERROR` - 错误
- `CRITICAL` - 严重错误

**示例:**
```
[2026-03-24 10:15:30] [INFO] [EVENT_HUB] System mode changed: normal → reduced | memory=87%
[2026-03-24 10:15:35] [SUCCESS] [AUTO_HEALER] Task fixed: 每日早报 | retries=2
[2026-03-24 10:16:00] [ERROR] [CRON] Task execution failed: 项目顾问 | error=model_not_found
[2026-03-24 10:16:05] [CRITICAL] [SYSTEM] Gateway unreachable | attempts=3
```

### memory/event-log.md (可读日志)

**格式 (Markdown):**
```markdown
## YYYY-MM-DD

### HH:mm - 事件类型
- **来源**: Agent 名称
- **严重性**: ℹ️/✅/⚠️/❌/🔴
- **详情**: 描述
- **动作**: 已执行的操作
- **状态**: ✅ 已解决 / ⏳ 处理中 / ❌ 失败
```

**示例:**
```markdown
## 2026-03-24

### 10:15 - 系统降载
- **来源**: 📡 事件协调员
- **严重性**: ⚠️
- **详情**: 内存使用率达到 87%，触发降载模式
- **动作**: 暂停低优先级任务
- **状态**: ✅ 已解决

### 10:16 - 任务失败
- **来源**: 💼 项目顾问
- **严重性**: ❌
- **详情**: 模型配置错误
- **动作**: 通知故障自愈员
- **状态**: ⏳ 处理中
```

## 事件类型代码

| 代码 | 说明 | 严重性 |
|------|------|--------|
| `MODE_CHANGE` | 系统模式切换 | WARNING |
| `TASK_SUCCESS` | 任务执行成功 | SUCCESS |
| `TASK_FAILED` | 任务执行失败 | ERROR |
| `TASK_RECOVERED` | 任务自动恢复 | SUCCESS |
| `RESOURCE_WARNING` | 资源告警 | WARNING |
| `RESOURCE_CRITICAL` | 资源严重不足 | CRITICAL |
| `GATEWAY_DOWN` | Gateway 故障 | CRITICAL |
| `GATEWAY_RESTARTED` | Gateway 重启 | WARNING |
| `AUTO_HEAL_SUCCESS` | 自动修复成功 | SUCCESS |
| `AUTO_HEAL_FAILED` | 自动修复失败 | ERROR |
| `CONFIG_CHANGED` | 配置变更 | INFO |
| `SECURITY_ALERT` | 安全告警 | CRITICAL |

## 日志轮转策略

### events.log
- 文件大小 > 100MB → 压缩为 events.log.1.gz
- 保留最近 7 个压缩文件
- 总大小 > 1GB → 删除最旧文件

### event-log.md
- 每天一个新文件 (event-log-YYYY-MM-DD.md)
- 保留最近 30 天
- 每月合并为一个归档文件

## 查询工具

### PowerShell 查询函数

```powershell
function Get-Events {
    param(
        [string]$Severity,
        [string]$Source,
        [DateTime]$From,
        [DateTime]$To,
        [int]$Limit = 100
    )
    
    $logPath = "memory/events.log"
    $events = Get-Content $logPath | Select-Object -Last $Limit
    
    if ($Severity) {
        $events = $events | Where-Object { $_ -match "\[$Severity\]" }
    }
    
    if ($Source) {
        $events = $events | Where-Object { $_ -match "\[$Source\]" }
    }
    
    return $events
}

function Get-EventSummary {
    param([int]$Hours = 24)
    
    $from = (Get-Date).AddHours(-$Hours)
    $events = Get-Events -From $from
    
    $summary = @{
        Total = $events.Count
        Info = ($events | Where-Object { $_ -match "\[INFO\]" }).Count
        Success = ($events | Where-Object { $_ -match "\[SUCCESS\]" }).Count
        Warning = ($events | Where-Object { $_ -match "\[WARNING\]" }).Count
        Error = ($events | Where-Object { $_ -match "\[ERROR\]" }).Count
        Critical = ($events | Where-Object { $_ -match "\[CRITICAL\]" }).Count
    }
    
    return $summary
}
```

## 集成规范

### 所有 Agent 必须遵守

1. **执行开始:**
   ```
   [timestamp] [INFO] [AGENT_NAME] Task started | task_id=xxx
   ```

2. **执行成功:**
   ```
   [timestamp] [SUCCESS] [AGENT_NAME] Task completed | duration=123s
   ```

3. **执行失败:**
   ```
   [timestamp] [ERROR] [AGENT_NAME] Task failed | error=xxx retries=2
   ```

4. **模式切换:**
   ```
   [timestamp] [WARNING] [SYSTEM] Mode changed: normal → reduced | reason=memory_high
   ```

5. **自动修复:**
   ```
   [timestamp] [SUCCESS] [AUTO_HEALER] Auto-fix applied | task=xxx fix=model_change
   ```
