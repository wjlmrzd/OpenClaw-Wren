# 日志轮转脚本
# 用途：压缩旧日志、清理过期文件、释放磁盘空间

param(
    [int]$DaysToKeep = 7,
    [int]$DaysToDelete = 30,
    [string]$LogsDir = "D:\OpenClaw\.openclaw\agents\main\sessions",
    [string]$CronLogsDir = "D:\OpenClaw\.openclaw\cron"
)

$ErrorActionPreference = "Stop"
$report = @()
$spaceBefore = (Get-PSDrive D).Free / 1GB

Write-Host "=== 日志清理开始 ===" -ForegroundColor Cyan
Write-Host "开始时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "日志目录：$LogsDir"
Write-Host "保留天数：$DaysToKeep 天"
Write-Host "删除阈值：$DaysToDelete 天"
Write-Host ""

# 1. 压缩超过保留期的 .jsonl 文件
Write-Host "📦 压缩旧会话日志..." -ForegroundColor Yellow
$filesToCompress = Get-ChildItem -Path $LogsDir -Filter "*.jsonl" | 
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$DaysToKeep) } |
    Where-Object { -not $_.Name.EndsWith(".gz") }

foreach ($file in $filesToCompress) {
    try {
        $gzipPath = "$($file.FullName).gz"
        $input = $file.OpenRead()
        $output = [System.IO.File]::Create($gzipPath)
        $gzip = New-Object System.IO.Compression.GzipStream($output, [System.IO.Compression.CompressionMode]::Compress)
        $input.CopyTo($gzip)
        $gzip.Close()
        $input.Close()
        $output.Close()
        
        # 删除原文件
        Remove-Item $file.FullName -Force
        $report += "✅ 压缩：$($file.Name) → $([math]::Round($file.Length/1MB, 2))MB"
    } catch {
        $report += "❌ 失败：$($file.Name) - $($_.Exception.Message)"
    }
}

# 2. 删除超过删除阈值的压缩文件
Write-Host "🗑️ 删除过期压缩日志..." -ForegroundColor Yellow
$filesToDelete = Get-ChildItem -Path $LogsDir -Filter "*.jsonl.gz" | 
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$DaysToDelete) }

foreach ($file in $filesToDelete) {
    try {
        Remove-Item $file.FullName -Force
        $report += "🗑️ 删除：$($file.Name)"
    } catch {
        $report += "❌ 删除失败：$($file.Name) - $($_.Exception.Message)"
    }
}

# 3. 清理 cron 运行历史（保留最近 50 条）
Write-Host "📋 清理 Cron 运行历史..." -ForegroundColor Yellow
$cronRunsFile = Join-Path $CronLogsDir "runs.json"
if (Test-Path $cronRunsFile) {
    try {
        $runsData = Get-Content $cronRunsFile -Raw | ConvertFrom-Json
        if ($runsData.PSObject.Properties['runs'] -and $runsData.runs.Count -gt 50) {
            $runsData.runs = $runsData.runs | Select-Object -Last 50
            $runsData | ConvertTo-Json -Depth 10 | Set-Content $cronRunsFile -Encoding UTF8
            $report += "✅ Cron 历史已清理（保留最近 50 条）"
        } else {
            $report += "ℹ️ Cron 历史记录正常 ($($runsData.runs.Count) 条)"
        }
    } catch {
        $report += "❌ Cron 历史清理失败：$($_.Exception.Message)"
    }
}

# 4. 计算释放空间
$spaceAfter = (Get-PSDrive D).Free / 1GB
$spaceFreed = $spaceAfter - $spaceBefore

Write-Host ""
Write-Host "=== 清理报告 ===" -ForegroundColor Cyan
Write-Host "清理前可用空间：$([math]::Round($spaceBefore, 2)) GB"
Write-Host "清理后可用空间：$([math]::Round($spaceAfter, 2)) GB"
Write-Host "释放空间：$([math]::Round($spaceFreed, 2)) GB"
Write-Host ""
Write-Host "操作详情:" -ForegroundColor Yellow
$report | ForEach-Object { Write-Host "  $_" }

# 输出 JSON 报告（供 OpenClaw 读取）
$jsonReport = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    spaceBeforeGB = [math]::Round($spaceBefore, 2)
    spaceAfterGB = [math]::Round($spaceAfter, 2)
    spaceFreedGB = [math]::Round($spaceFreed, 2)
    filesCompressed = ($filesToCompress | Measure-Object).Count
    filesDeleted = ($filesToDelete | Measure-Object).Count
    details = $report
} | ConvertTo-Json -Depth 5

$jsonReport | Out-File -FilePath "D:\OpenClaw\.openclaw\workspace\logs\log-cleanup-report.json" -Encoding UTF8

Write-Host ""
Write-Host "✅ 日志清理完成" -ForegroundColor Green
