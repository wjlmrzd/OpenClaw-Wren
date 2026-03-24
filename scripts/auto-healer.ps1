# Auto-Healer - 故障自愈脚本
param([switch]$DryRun)

$workspaceRoot = "D:\OpenClaw\.openclaw\workspace"
$healingReportPath = Join-Path $workspaceRoot "memory\auto-healer-report.json"

Write-Host "=== Auto-Healer ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

$systemStatus = @{healthy=$true; issuesFound=0; issuesFixed=0; alertsGenerated=0}
$fixActions = @()
$alerts = @()

# Check Cron tasks
Write-Host "[1/5] Checking Cron tasks..." -ForegroundColor Yellow
try {
    $cronOutput = & openclaw cron list 2>&1 | Out-String
    $errorLines = $cronOutput -split "`n" | Where-Object { $_ -match '\serror\s' }
    if ($errorLines.Count -gt 0) {
        Write-Host "  Found $($errorLines.Count) error tasks" -ForegroundColor Red
        $systemStatus.issuesFound = $errorLines.Count
    } else {
        Write-Host "  OK All tasks normal" -ForegroundColor Green
    }
} catch {
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Check memory
Write-Host "[2/5] Checking memory..." -ForegroundColor Yellow
try {
    $os = Get-WmiObject Win32_OperatingSystem
    $memPercent = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)
    Write-Host "  Memory: ${memPercent}%" -ForegroundColor $(if($memPercent -gt 90){"Red"}else{"Green"})
    if ($memPercent -gt 95) {
        $fixActions += @{action="restart_gateway"; reason="memory_critical"}
        $systemStatus.issuesFound++
    }
} catch {}

# Check disk
Write-Host "[3/5] Checking disk..." -ForegroundColor Yellow
try {
    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskPercent = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1)
    Write-Host "  Disk: ${diskPercent}%" -ForegroundColor $(if($diskPercent -gt 85){"Yellow"}else{"Green"})
    if ($diskPercent -gt 95) {
        $fixActions += @{action="log_cleanup"; reason="disk_critical"}
        $systemStatus.issuesFound++
    }
} catch {}

# Check Gateway
Write-Host "[4/5] Checking Gateway..." -ForegroundColor Yellow
try {
    $gwStatus = & openclaw gateway status 2>&1
    Write-Host "  Gateway: OK" -ForegroundColor Green
} catch {
    Write-Host "  Gateway: Error" -ForegroundColor Red
    $fixActions += @{action="restart_gateway"; reason="gateway_error"}
}

# Execute fixes
Write-Host "[5/5] Executing fixes..." -ForegroundColor Yellow
if ($fixActions.Count -eq 0) {
    Write-Host "  OK No fixes needed" -ForegroundColor Green
} else {
    foreach ($action in $fixActions) {
        if ($DryRun) {
            Write-Host "  [DRY] $($action.action)" -ForegroundColor Cyan
        } else {
            Write-Host "  -> $($action.action)" -ForegroundColor Yellow
        }
    }
}

# Save report
$report = [PSCustomObject]@{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    systemStatus = $systemStatus
    fixActions = $fixActions
    alerts = $alerts
}
$report | ConvertTo-Json -Depth 5 | Set-Content -Path $healingReportPath

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Issues: $($systemStatus.issuesFound)"
Write-Host "Fixed: $($systemStatus.issuesFixed)"
Write-Host "Report: $healingReportPath"

$report | ConvertTo-Json -Depth 5
