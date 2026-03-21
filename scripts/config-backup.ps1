# 配置备份脚本
# 用途：创建配置文件快照、生成变更差异

param(
    [string]$BackupDir = "D:\OpenClaw\.openclaw\workspace\memory\config-backups",
    [string]$OpenClawConfig = "D:\OpenClaw\.openclaw\openclaw.json",
    [string]$CronJobsFile = "D:\OpenClaw\.openclaw\cron\jobs.json"
)

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

Write-Host "=== 配置备份开始 ===" -ForegroundColor Cyan
Write-Host "时间：$timestamp"

# 创建备份目录
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    Write-Host "✅ 创建备份目录：$BackupDir"
}

# 备份 openclaw.json
if (Test-Path $OpenClawConfig) {
    $backupPath = Join-Path $BackupDir "openclaw-$timestamp.json"
    Copy-Item $OpenClawConfig $backupPath
    Write-Host "✅ 备份 openclaw.json → $backupPath"
}

# 备份 cron jobs
if (Test-Path $CronJobsFile) {
    $backupPath = Join-Path $BackupDir "cron-jobs-$timestamp.json"
    Copy-Item $CronJobsFile $backupPath
    Write-Host "✅ 备份 cron/jobs.json → $backupPath"
}

# 清理旧备份（保留最近 10 个）
$oldBackups = Get-ChildItem -Path $BackupDir -Filter "*.json" | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -Skip 10

foreach ($old in $oldBackups) {
    Remove-Item $old.FullName -Force
    Write-Host "🗑️ 删除旧备份：$($old.Name)"
}

Write-Host ""
Write-Host "✅ 配置备份完成" -ForegroundColor Green
Write-Host "备份位置：$BackupDir"
