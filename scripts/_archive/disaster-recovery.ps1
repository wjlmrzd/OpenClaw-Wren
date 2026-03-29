# 灾难恢复 - 完整系统快照
# 用途：每周创建完整配置和任务快照

param(
    [string]$RecoveryDir = "D:\OpenClaw\.openclaw\workspace\memory\disaster-recovery",
    [string]$Timestamp = ""
)

$ErrorActionPreference = "Stop"

if (-not $Timestamp) {
    $Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
}

Write-Host "=== 灾难恢复快照 ===" -ForegroundColor Cyan
Write-Host "时间：$Timestamp"

# 创建恢复目录
if (-not (Test-Path $RecoveryDir)) {
    New-Item -ItemType Directory -Path $RecoveryDir -Force | Out-Null
}

$snapshotDir = Join-Path $RecoveryDir $Timestamp
New-Item -ItemType Directory -Path $snapshotDir -Force | Out-Null

# 1. 导出 Cron 任务配置
Write-Host "📋 导出 Cron 任务配置..."
$cronExport = @()
# 这里需要通过 openclaw cron list 获取，脚本仅做框架
$cronConfig = @{
    exportTime = $Timestamp
    note = "Use 'openclaw cron list' to export current jobs"
} | ConvertTo-Json
$cronConfig | Out-File -FilePath (Join-Path $snapshotDir "cron-config.json") -Encoding UTF8

# 2. 备份关键配置文件
$configFiles = @(
    "D:\OpenClaw\.openclaw\openclaw.json",
    "D:\OpenClaw\.openclaw\credentials\telegram-allowFrom.json",
    "D:\OpenClaw\.openclaw\agents\main\agent\models.json"
)

foreach ($file in $configFiles) {
    if (Test-Path $file) {
        $dest = Join-Path $snapshotDir (Split-Path $file -Leaf)
        Copy-Item $file $dest
        Write-Host "✅ 备份：$($file | Split-Path -Leaf)"
    }
}

# 3. 生成恢复指南
$recoveryGuide = @"
# 灾难恢复指南
**创建时间**: $Timestamp

## 快速恢复步骤

### 1. 恢复配置文件
\`\`\`powershell
# 恢复 openclaw.json
Copy-Item "$snapshotDir\openclaw.json" "D:\OpenClaw\.openclaw\openclaw.json"

# 恢复 Telegram 白名单
Copy-Item "$snapshotDir\telegram-allowFrom.json" "D:\OpenClaw\.openclaw\credentials\telegram-allowFrom.json"
\`\`\`

### 2. 恢复 Cron 任务
\`\`\`powershell
# 手动重新创建任务（推荐）
openclaw cron add --name "任务名" --cron "表达式" --message "任务描述"
\`\`\`

### 3. 重启 Gateway
\`\`\`powershell
openclaw gateway restart
\`\`\`

## 备份文件清单
- openclaw.json
- telegram-allowFrom.json
- models.json
- cron-config.json

## 联系支持
如恢复失败，请检查：
1. OpenClaw 版本兼容性
2. 配置文件格式
3. 权限设置
"@

$recoveryGuide | Out-File -FilePath (Join-Path $snapshotDir "RECOVERY-GUIDE.md") -Encoding UTF8

Write-Host ""
Write-Host "✅ 灾难恢复快照完成" -ForegroundColor Green
Write-Host "快照位置：$snapshotDir"
