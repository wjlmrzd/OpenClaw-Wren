# Auto-Healer 辅助工具

## PowerShell 脚本：修复 Cron 任务

### 1. 备份 jobs.json

```powershell
# backup-jobs.ps1
param(
    [string]$BackupDir = "D:\OpenClaw\.openclaw\workspace\memory\auto-healer-backups"
)

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$jobsPath = "D:\OpenClaw\.openclaw\cron\jobs.json"
$backupPath = Join-Path $BackupDir "jobs-backup-$timestamp.json"

if (!(Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir | Out-Null
}

Copy-Item -Path $jobsPath -Destination $backupPath
Write-Host "✅ 备份完成：$backupPath"
return $backupPath
```

### 2. 修复模型配置

```powershell
# fix-model-config.ps1
param(
    [string]$JobId,
    [string]$CorrectModel
)

$jobsPath = "D:\OpenClaw\.openclaw\cron\jobs.json"
$jobs = Get-Content $jobsPath -Raw | ConvertFrom-Json

$job = $jobs.jobs | Where-Object { $_.id -eq $JobId }
if ($job) {
    $oldModel = $job.payload.model
    $job.payload.model = $CorrectModel
    $job.updatedAtMs = [int][double]::Parse((Get-Date -UFormat %s) + "000")
    
    $jobs | ConvertTo-Json -Depth 100 | Set-Content $jobsPath -Encoding UTF8
    Write-Host "✅ 模型已修复：$JobId"
    Write-Host "   旧：$oldModel"
    Write-Host "   新：$CorrectModel"
} else {
    Write-Error "❌ 未找到任务：$JobId"
    exit 1
}
```

### 3. 增加超时时间

```powershell
# increase-timeout.ps1
param(
    [string]$JobId,
    [int]$Multiplier = 2  # 默认翻倍
)

$jobsPath = "D:\OpenClaw\.openclaw\cron\jobs.json"
$jobs = Get-Content $jobsPath -Raw | ConvertFrom-Json

$job = $jobs.jobs | Where-Object { $_.id -eq $JobId }
if ($job) {
    $oldTimeout = $job.payload.timeoutSeconds
    $newTimeout = $oldTimeout * $Multiplier
    
    $job.payload.timeoutSeconds = $newTimeout
    $job.updatedAtMs = [int][double]::Parse((Get-Date -UFormat %s) + "000")
    
    $jobs | ConvertTo-Json -Depth 100 | Set-Content $jobsPath -Encoding UTF8
    Write-Host "✅ 超时已调整：$JobId"
    Write-Host "   旧：${oldTimeout}s"
    Write-Host "   新：${newTimeout}s"
} else {
    Write-Error "❌ 未找到任务：$JobId"
    exit 1
}
```

### 4. 重试失败任务

```powershell
# retry-job.ps1
param(
    [string]$JobId
)

$jobPath = "D:\OpenClaw\.openclaw\cron\jobs.json"
$jobs = Get-Content $jobPath -Raw | ConvertFrom-Json

$job = $jobs.jobs | Where-Object { $_.id -eq $JobId }
if ($job) {
    # 清除错误状态
    $job.state.consecutiveErrors = 0
    $job.state.lastError = $null
    $job.state.lastStatus = "pending_retry"
    
    $jobs | ConvertTo-Json -Depth 100 | Set-Content $jobPath -Encoding UTF8
    
    # 触发立即执行
    & openclaw cron run --id $JobId
    
    Write-Host "✅ 任务已触发重试：$JobId"
} else {
    Write-Error "❌ 未找到任务：$JobId"
    exit 1
}
```

### 5. 诊断工具

```powershell
# diagnose-job.ps1
param(
    [string]$JobId
)

$jobPath = "D:\OpenClaw\.openclaw\cron\jobs.json"
$jobs = Get-Content $jobPath -Raw | ConvertFrom-Json

$job = $jobs.jobs | Where-Object { $_.id -eq $JobId }
if (!$job) {
    Write-Error "❌ 未找到任务：$JobId"
    exit 1
}

Write-Host "📋 任务诊断报告：$($job.name)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "ID:           $($job.id)"
Write-Host "状态：        $(if($job.enabled){'✅ 启用'}else{'❌ 禁用'})"
Write-Host "模型：        $($job.payload.model)"
Write-Host "超时：        $($job.payload.timeoutSeconds)s"
Write-Host "调度：        $($job.schedule.expr)"
Write-Host ""
Write-Host "📊 执行历史:"
Write-Host "  最后运行：  $(if($job.state.lastRunAtMs){[DateTimeOffset]::FromUnixTimeMilliseconds($job.state.lastRunAtMs).LocalDateTime}else{'从未'})"
Write-Host "  最后状态：  $($job.state.lastStatus)"
Write-Host "  连续失败：  $($job.state.consecutiveErrors)"
if ($job.state.lastError) {
    Write-Host "  错误信息：  $($job.state.lastError)" -ForegroundColor Red
}
Write-Host ""

# 错误分析
if ($job.state.lastError) {
    Write-Host "🔍 错误分析:" -ForegroundColor Yellow
    
    if ($job.state.lastError -match "Unknown model") {
        Write-Host "  → 类型：模型配置错误" -ForegroundColor Red
        Write-Host "  → 建议：修复 model 字段为 dashscope-coding-plan/xxx 格式"
    }
    elseif ($job.state.lastError -match "timed out") {
        Write-Host "  → 类型：执行超时" -ForegroundColor Yellow
        Write-Host "  → 建议：增加 timeoutSeconds 或优化任务逻辑"
    }
    elseif ($job.state.lastError -match "powershell|python|script") {
        Write-Host "  → 类型：脚本异常" -ForegroundColor Orange
        Write-Host "  → 建议：检查脚本路径和语法"
    }
    else {
        Write-Host "  → 类型：未知错误" -ForegroundColor Gray
        Write-Host "  → 建议：查看详细日志"
    }
}
```

### 6. 一键修复脚本

```powershell
# auto-fix.ps1
param(
    [string]$JobId
)

Write-Host "🚑 Auto-Healer 一键修复" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. 备份
& .\backup-jobs.ps1

# 2. 诊断
& .\diagnose-job.ps1 -JobId $JobId

# 3. 获取任务信息
$jobPath = "D:\OpenClaw\.openclaw\cron\jobs.json"
$jobs = Get-Content $jobPath -Raw | ConvertFrom-Json
$job = $jobs.jobs | Where-Object { $_.id -eq $JobId }

if (!$job) { exit 1 }

$errorMsg = $job.state.lastError

# 4. 自动修复
if ($errorMsg -match "Unknown model") {
    Write-Host "`n🔧 检测到模型错误，正在修复..." -ForegroundColor Yellow
    
    # 提取错误中的模型名
    if ($errorMsg -match "anthropic/(qwen[\w.-]+)") {
        $correctModel = "dashscope-coding-plan/$($matches[1])"
        & .\fix-model-config.ps1 -JobId $JobId -CorrectModel $correctModel
    }
    elseif ($errorMsg -match "Unknown model: ([\w./-]+)") {
        $wrongModel = $matches[1]
        # 尝试自动纠正
        if ($wrongModel -match "^qwen") {
            $correctModel = "dashscope-coding-plan/$wrongModel"
        }
        elseif ($wrongModel -match "^glm") {
            $correctModel = "dashscope-coding-plan/$wrongModel"
        }
        else {
            Write-Host "⚠️ 无法自动纠正模型：$wrongModel" -ForegroundColor Orange
            exit 1
        }
        & .\fix-model-config.ps1 -JobId $JobId -CorrectModel $correctModel
    }
}
elseif ($errorMsg -match "timed out") {
    Write-Host "`n🔧 检测到超时错误，正在增加超时..." -ForegroundColor Yellow
    & .\increase-timeout.ps1 -JobId $JobId -Multiplier 2
}

# 5. 重试
Write-Host "`n🔄 触发重试..." -ForegroundColor Yellow
& .\retry-job.ps1 -JobId $JobId

Write-Host "`n✅ 修复流程完成" -ForegroundColor Green
```

---

## 使用方法

### 诊断任务
```powershell
cd D:\OpenClaw\.openclaw\workspace\scripts
.\diagnose-job.ps1 -JobId "2bb2b058-da87-486a-a400-b871cd5cf8a4"
```

### 一键修复
```powershell
.\auto-fix.ps1 -JobId "2bb2b058-da87-486a-a400-b871cd5cf8a4"
```

### 手动修复模型
```powershell
.\fix-model-config.ps1 -JobId "2bb2b058-da87-486a-a400-b871cd5cf8a4" -CorrectModel "dashscope-coding-plan/qwen3.5-plus"
```

### 手动增加超时
```powershell
.\increase-timeout.ps1 -JobId "c73f1ecf-9f61-47c5-bea1-1c4f322e2ebe" -Multiplier 2
```
