# 系统状态模块 - 查看资源使用、Gateway 状态
# 由 unified-maintenance-console.ps1 调用

$ErrorActionPreference = "Continue"

function Get-SystemInfo {
    param([string]$Title)
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Get-OpenClawStatus {
    # Gateway 状态
    Write-Host "[1] Gateway 状态" -ForegroundColor Yellow
    try {
        $status = openclaw gateway status 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  状态: " -NoNewline
            Write-Host "运行中" -ForegroundColor Green
        } else {
            Write-Host "  状态: " -NoNewline
            Write-Host "异常" -ForegroundColor Red
        }
    } catch {
        Write-Host "  状态: " -NoNewline
        Write-Host "无法获取" -ForegroundColor Red
    }
    Write-Host ""
}

function Get-SystemResources {
    # CPU 使用率
    Write-Host "[2] 系统资源" -ForegroundColor Yellow
    $cpu = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1).CounterSamples.CookedValue
    Write-Host ("  CPU: {0:N1}%" -f $cpu) -ForegroundColor $(if ($cpu -gt 80) { "Red" } elseif ($cpu -gt 60) { "Yellow" } else { "Green" })
    
    # 内存使用率
    $os = Get-CimInstance Win32_OperatingSystem
    $memUsed = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)
    $memTotal = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $memPercent = [math]::Round(($memUsed / $memTotal) * 100, 1)
    Write-Host ("  内存: {0:N1}% ({1:N1} / {2:N1} GB)" -f $memPercent, $memUsed, $memTotal) -ForegroundColor $(if ($memPercent -gt 85) { "Red" } elseif ($memPercent -gt 70) { "Yellow" } else { "Green" })
    
    # 磁盘使用率
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskUsed = [math]::Round($disk.Size / 1GB - $disk.FreeSpace / 1GB, 1)
    $diskTotal = [math]::Round($disk.Size / 1GB, 1)
    $diskPercent = [math]::Round(($diskUsed / $diskTotal) * 100, 1)
    Write-Host ("  磁盘: {0:N1}% ({1:N1} / {2:N1} GB)" -f $diskPercent, $diskUsed, $diskTotal) -ForegroundColor $(if ($diskPercent -gt 90) { "Red" } elseif ($diskPercent -gt 80) { "Yellow" } else { "Green" })
    Write-Host ""
}

function Get-OpenClawInfo {
    Write-Host "[3] OpenClaw 信息" -ForegroundColor Yellow
    Write-Host "  版本: v0.1.9"
    Write-Host "  配置目录: $env:USERPROFILE\.openclaw"
    Write-Host "  工作目录: $(Get-Location)"
    Write-Host ""
}

function Get-RecentEvents {
    Write-Host "[4] 最近事件" -ForegroundColor Yellow
    $logPath = Join-Path $env:USERPROFILE ".openclaw\logs\events.log"
    if (Test-Path $logPath) {
        Get-Content $logPath -Tail 5 | ForEach-Object {
            Write-Host "  $_"
        }
    } else {
        Write-Host "  暂无事件记录" -ForegroundColor Gray
    }
    Write-Host ""
}

function Main {
    Get-SystemInfo "系统状态"
    
    Get-OpenClawStatus
    Get-SystemResources
    Get-OpenClawInfo
    Get-RecentEvents
    
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "按 Enter 返回主菜单..." -ForegroundColor Gray
    Read-Host
}

Main
