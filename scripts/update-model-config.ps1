#!/usr/bin/env pwsh
# 更新 Cron 任务模型配置 - 根据模型调度策略
# 编码：UTF-8

$JOBS_FILE = "D:\OpenClaw\.openclaw\cron\jobs.json"
$BACKUP_DIR = "D:\OpenClaw\.openclaw\workspace\memory\model-config-backups"

# 创建备份目录
if (!(Test-Path $BACKUP_DIR)) {
    New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null
}

# 备份当前配置
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupFile = Join-Path $BACKUP_DIR "jobs-backup-$timestamp.json"
Copy-Item $JOBS_FILE $backupFile
Write-Host "Backup created: $backupFile"

# 读取当前配置
$jobs = Get-Content $JOBS_FILE -Raw -Encoding utf8 | ConvertFrom-Json

# 模型映射 (使用任务 ID 或名称匹配)
$MODEL_MAP = @{
    # 知识类 -> qwen3.5-plus
    '📧 邮件监控员' = 'dashscope-coding-plan/qwen3.5-plus'
    '🏃 运动提醒员' = 'dashscope-coding-plan/qwen3.5-plus'
    '📰 每日早报' = 'dashscope-coding-plan/qwen3.5-plus'
    '🌐 网站监控员' = 'dashscope-coding-plan/qwen3.5-plus'
    '💼 项目顾问' = 'dashscope-coding-plan/qwen3.5-plus'
    '📡 事件协调员' = 'dashscope-coding-plan/qwen3.5-plus'
    '🌅 早晨摘要' = 'dashscope-coding-plan/qwen3.5-plus'
    '🔔 通知协调员' = 'dashscope-coding-plan/qwen3.5-plus'
    '🧠 知识整理员' = 'dashscope-coding-plan/qwen3.5-plus'
    '🧬 知识演化员' = 'dashscope-coding-plan/qwen3.5-plus'
    '⚖️ 资源守护者' = 'dashscope-coding-plan/qwen3.5-plus'
    
    # 分析类 -> glm-5
    '🛡️ 安全审计员' = 'dashscope-coding-plan/glm-5'
    '📊 运营总监' = 'dashscope-coding-plan/glm-5'
    '📈 每周总结' = 'dashscope-coding-plan/glm-5'
    '🚨 灾难恢复官' = 'dashscope-coding-plan/glm-5'
    '💰 成本分析师' = 'dashscope-coding-plan/glm-5'
    '🧠 调度优化员' = 'dashscope-coding-plan/glm-5'
    '🔍 系统自检员' = 'dashscope-coding-plan/glm-5'
    
    # 结构类 -> qwen3-coder-plus / qwen3-coder-next
    '🏥 健康监控员' = 'dashscope-coding-plan/qwen3-coder-plus'
    '📝 配置审计师' = 'dashscope-coding-plan/qwen3-coder-plus'
    '🧪 回归测试员' = 'dashscope-coding-plan/qwen3-coder-plus'
    '💾 备份管理员' = 'dashscope-coding-plan/qwen3-coder-next'
    '🚑 故障自愈员' = 'dashscope-coding-plan/qwen3-coder-next'
    '🧹 日志清理员' = 'dashscope-coding-plan/qwen3-coder-next'
    '🛠️ 每日维护员' = 'dashscope-coding-plan/qwen3-coder-next'
}

# 更新任务模型
$updated = 0
$unchanged = 0
$changes = @()

foreach ($job in $jobs.jobs) {
    $taskName = $job.name
    $oldModel = $job.payload.model
    
    if ($MODEL_MAP.ContainsKey($taskName)) {
        $newModel = $MODEL_MAP[$taskName]
        
        if ($oldModel -ne $newModel) {
            $job.payload.model = $newModel
            $updated++
            $changes += [PSCustomObject]@{
                task = $taskName
                old = $oldModel
                new = $newModel
            }
            Write-Host "UPDATE: $taskName"
            Write-Host "  $oldModel -> $newModel"
        } else {
            $unchanged++
        }
    } else {
        Write-Host "SKIP: $taskName (not mapped, keeping $oldModel)"
    }
}

# 保存更新后的配置
$jobs | ConvertTo-Json -Depth 10 | Set-Content -Path $JOBS_FILE -Encoding utf8

Write-Host ""
Write-Host "=== Update Complete ==="
Write-Host "Updated: $updated tasks"
Write-Host "Unchanged: $unchanged tasks"

# 生成变更报告
$reportFile = Join-Path $BACKUP_DIR "model-changes-$timestamp.md"
$report = "# Model Configuration Change Report`n`n"
$report += "**Time**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")`n"
$report += "**Backup**: $backupFile`n`n"
$report += "## Changes`n`n"
$report += "| Task | Old Model | New Model | Type |`n"
$report += "|------|-----------|-----------|------|`n"

foreach ($change in $changes) {
    $taskType = switch ($change.new) {
        'dashscope-coding-plan/qwen3.5-plus' { 'Knowledge' }
        'dashscope-coding-plan/glm-5' { 'Analysis' }
        'dashscope-coding-plan/qwen3-coder-plus' { 'Structure' }
        'dashscope-coding-plan/qwen3-coder-next' { 'Structure (Fast)' }
        default { 'Unknown' }
    }
    $report += "| $($change.task) | $($change.old) | $($change.new) | $taskType |`n"
}

$report += "`n## Next Steps`n`n"
$report += "1. Restart Gateway: \`openclaw gateway restart\`"
$report += "`n2. Monitor model performance: \`.\scripts\model-scheduler.ps1 -Action stats\`"
$report += "`n3. Verify tasks execute normally`n"

$report | Set-Content -Path $reportFile -Encoding utf8
Write-Host ""
Write-Host "Report: $reportFile"
