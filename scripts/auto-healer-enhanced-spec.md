# 强化故障自愈员规格

## 核心能力升级

### 1. 自动重试机制

**重试策略:**
```
第 1 次失败 → 等待 1 分钟 → 重试
第 2 次失败 → 等待 5 分钟 → 重试
第 3 次失败 → 等待 15 分钟 → 重试
第 4 次失败 → 标记为需要人工干预
```

**重试配置:**
```json
{
  "retry": {
    "maxAttempts": 3,
    "delays": [60, 300, 900],
    "backoffMultiplier": 5
  }
}
```

### 2. 模型自动切换

**主模型失败时:**
```
dashscope-coding-plan/qwen3.5-plus (主)
  ↓ 失败
dashscope-coding-plan/glm-5 (备用 1)
  ↓ 失败
dashscope-coding-plan/kimi-k2.5 (备用 2)
  ↓ 失败
标记任务，发送告警
```

**切换逻辑:**
```powershell
$primaryModel = "dashscope-coding-plan/qwen3.5-plus"
$backupModels = @(
    "dashscope-coding-plan/glm-5",
    "dashscope-coding-plan/kimi-k2.5"
)

foreach ($model in ($primaryModel, $backupModels)) {
    try {
        $result = Invoke-Task -Model $model
        if ($result.Success) {
            Write-Log "模型切换成功：$model"
            break
        }
    }
    catch {
        Write-Log "模型失败：$model - $($_.Exception.Message)"
    }
}
```

### 3. Gateway 自动重启

**重启策略:**
```
检测到 Gateway 异常
  ↓
尝试软重启 (SIGUSR1)
  ↓ 失败
等待 30 秒
  ↓
尝试硬重启 (restart)
  ↓ 失败
等待 60 秒
  ↓
发送紧急通知 + 进入安全模式
```

**重启命令:**
```powershell
# 软重启
openclaw gateway restart --graceful

# 硬重启
openclaw gateway restart --force

# 验证
openclaw gateway status
```

### 4. 事件记录与升级

**连续失败处理:**

| 连续失败次数 | 动作 |
|-------------|------|
| 1-2 次 | 自动重试，记录日志 |
| 3 次 | 记录到 incident-log.md，Telegram 通知 |
| 5 次 | 暂停任务，发送紧急告警 |
| 10 次 | 进入安全模式，等待人工干预 |

**事件记录格式:**
```markdown
## 事件记录 - YYYY-MM-DD

### 事件 ID: INC-20260324-001
- **时间**: 2026-03-24 10:15:30
- **任务**: 💼 项目顾问
- **错误类型**: 模型配置错误
- **连续失败**: 3 次
- **已尝试修复**: 
  - 重试 (3 次)
  - 模型切换 (qwen3.5-plus → glm-5)
  - 配置检查
- **当前状态**: 等待人工干预
- **建议动作**: 检查模型配置
```

### 5. 智能诊断

**诊断流程:**
```
任务失败
  ↓
1. 检查错误类型
   - 模型错误 → 切换模型
   - 超时错误 → 增加 timeout
   - 配置错误 → 从备份恢复
   - 资源错误 → 清理资源
  ↓
2. 尝试修复
  ↓
3. 验证修复
  ↓
4. 记录结果
```

**诊断规则库:**
```json
{
  "diagnosis": {
    "model_not_found": {
      "action": "switch_model",
      "priority": ["glm-5", "kimi-k2.5"]
    },
    "timeout": {
      "action": "increase_timeout",
      "multiplier": 1.5
    },
    "config_invalid": {
      "action": "restore_backup",
      "backup_path": "memory/auto-healer-backups/"
    },
    "memory_high": {
      "action": "trigger_cleanup",
      "threshold": 85
    }
  }
}
```

### 6. 备份与恢复

**备份策略:**
- 每次修改配置前自动备份
- 备份位置：`memory/auto-healer-backups/`
- 备份命名：`config-backup-YYYYMMDD-HHMMSS.json`
- 保留数量：最近 10 个备份

**恢复流程:**
```powershell
function Restore-FromBackup {
    param([string]$ConfigType)
    
    $backupDir = "memory/auto-healer-backups"
    $latestBackup = Get-ChildItem "$backupDir/$ConfigType*.json" | 
                    Sort-Object LastWriteTime -Descending | 
                    Select-Object -First 1
    
    if ($latestBackup) {
        Copy-Item $latestBackup.FullName "$ConfigType.json" -Force
        Write-Log "已从备份恢复：$($latestBackup.Name)"
        return $true
    }
    
    return $false
}
```

### 7. 通知升级策略

**通知规则:**

| 情况 | 通知方式 | 时间 |
|------|---------|------|
| 首次失败 | 不通知 | - |
| 连续 3 次失败 | Telegram | 立即 |
| 连续 5 次失败 | Telegram + 标记紧急 | 立即 |
| Gateway 重启失败 | Telegram + 紧急 | 立即 |
| 系统进入安全模式 | Telegram + 紧急 | 立即 |

**通知格式:**
```
🚨 故障自愈告警 - HH:mm

任务：[任务名称]
连续失败：X 次
错误类型：[错误描述]
已尝试修复：
- [修复动作 1]
- [修复动作 2]

当前状态：[状态]
建议动作：[建议]

事件 ID: INC-YYYYMMDD-XXX
```

---

## 与其他组件的联动

### 与系统模式控制器
- 连续失败≥3 → 建议进入降载模式
- 连续失败≥5 → 建议进入安全模式

### 与事件协调员
- 修复成功 → 发送 SUCCESS 事件
- 修复失败 → 发送 ERROR 事件
- 需要升级 → 发送 CRITICAL 事件

### 与系统自检员
- 提供修复统计
- 提供事件记录
- 协助健康评分计算
