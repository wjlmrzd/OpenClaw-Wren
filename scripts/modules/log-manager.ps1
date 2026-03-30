# 日志管理模块 - 清理、压缩、导出日志
# 由 unified-maintenance-console.ps1 调用

$ErrorActionPreference = "Continue"

$LogDir = Join-Path $env:USERPROFILE ".openclaw\logs"
$BackupDir = Join-Path $env:USERPROFILE ".openclaw\logs\archive"

function Show-LogMenu {
    Clear-Host
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗"
    Write-Host "║                    日志管理 v1.0                             ║"
    Write-Host "╠══════════════════════════════════════════════════════════════╣"
    Write-Host "║  1. 查看日志列表       - 查看所有日志文件                      ║"
    Write-Host "║  2. 查看日志内容       - 实时查看日志内容                       ║"
    Write-Host "║  3. 清理旧日志         - 删除指定天数前的日志                   ║"
    Write-Host "║  4. 压缩日志           - 压缩并归档日志                        ║"
    Write-Host "║  5. 导出日志           - 导出日志到指定位置                    ║"
    Write-Host "║  6. 日志统计           - 显示日志大小统计                      ║"
    Write-Host "║  0. 返回                                                    ║"
    Write-Host "╚══════════════════════════════════════════════════════════════╝"
    Write-Host ""
}

function Get-LogList {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  日志文件列表" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-Path $LogDir)) {
        Write-Host "  日志目录不存在" -ForegroundColor Yellow
        return
    }
    
    $logs = Get-ChildItem $LogDir -Filter "*.log" | Sort-Object LastWriteTime -Descending
    if ($logs.Count -eq 0) {
        Write-Host "  没有日志文件" -ForegroundColor Gray
        return
    }
    
    $totalSize = 0
    $logs | ForEach-Object -Begin { $i = 1 } -Process {
        $sizeStr = if ($_.Length -lt 1KB) { "$($_.Length) B" }
                   elseif ($_.Length -lt 1MB) { "$([math]::Round($_.Length/1KB, 1)) KB" }
                   else { "$([math]::Round($_.Length/1MB, 1)) MB" }
        $dateStr = $_.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
        Write-Host ("  {0,2}. {1,-30} {2,10}  {3}" -f $i, $_.Name, $sizeStr, $dateStr)
        $totalSize += $_.Length
        $i++
    }
    
    Write-Host ""
    Write-Host ("  总计: {0} 个文件, {1:N2} MB" -f $logs.Count, ($totalSize/1MB)) -ForegroundColor Yellow
}

function Show-LogContent {
    Get-LogList
    Write-Host ""
    $logName = Read-Host "请输入日志文件名 (或直接回车查看 events.log)"
    if ([string]::IsNullOrWhiteSpace($logName)) {
        $logName = "events.log"
    }
    
    $logPath = Join-Path $LogDir $logName
    if (-not (Test-Path $logPath)) {
        Write-Host "  日志文件不存在: $logName" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  按 Ctrl+C 退出, Enter 继续滚动" -ForegroundColor Gray
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    Get-Content $logPath -Tail 50 -Wait
}

function Remove-OldLogs {
    Write-Host ""
    $days = Read-Host "请输入保留天数 (默认 7)"
    if ([string]::IsNullOrWhiteSpace($days)) { $days = 7 }
    $days = [int]$days
    
    if ($days -lt 1) {
        Write-Host "  天数必须大于 0" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    Write-Host ""
    Write-Host ("  正在删除 {0} 天前的日志..." -f $days) -ForegroundColor Yellow
    
    $cutoffDate = (Get-Date).AddDays(-$days)
    $oldLogs = Get-ChildItem $LogDir -Filter "*.log" | Where-Object { $_.LastWriteTime -lt $cutoffDate }
    
    if ($oldLogs.Count -eq 0) {
        Write-Host "  没有需要清理的日志" -ForegroundColor Green
    } else {
        $totalSize = ($oldLogs | Measure-Object Length -Sum).Sum
        $oldLogs | Remove-Item -Force
        Write-Host ("  已删除 {0} 个文件, 释放 {1:N2} MB" -f $oldLogs.Count, ($totalSize/1MB)) -ForegroundColor Green
    }
    
    Read-Host "按 Enter 继续"
}

function Compress-Logs {
    Write-Host ""
    Write-Host "  正在压缩日志..." -ForegroundColor Yellow
    
    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    }
    
    $archiveName = "logs_archive_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
    $archivePath = Join-Path $BackupDir $archiveName
    
    $logs = Get-ChildItem $LogDir -Filter "*.log"
    if ($logs.Count -eq 0) {
        Write-Host "  没有日志文件需要压缩" -ForegroundColor Yellow
    } else {
        Compress-Archive -Path $logs.FullName -DestinationPath $archivePath -Force
        Write-Host ("  已压缩到: {0}" -f $archivePath) -ForegroundColor Green
    }
    
    Read-Host "按 Enter 继续"
}

function Export-Logs {
    Write-Host ""
    $targetPath = Read-Host "请输入导出目录路径"
    if ([string]::IsNullOrWhiteSpace($targetPath)) {
        Write-Host "  路径不能为空" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    if (-not (Test-Path $targetPath)) {
        New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
    }
    
    $targetPath = Join-Path $targetPath "openclaw_logs_$(Get-Date -Format 'yyyyMMdd')"
    New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
    
    Copy-Item -Path "$LogDir\*" -Destination $targetPath -Filter "*.log" -Force
    Write-Host ("  已导出到: {0}" -f $targetPath) -ForegroundColor Green
    
    Read-Host "按 Enter 继续"
}

function Get-LogStats {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write