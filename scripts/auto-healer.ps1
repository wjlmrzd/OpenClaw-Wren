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

# Check disk (D: - Workspace drive)
Write-Host "[3/5] Checking disk..." -ForegroundColor Yellow
try {
    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='D:'"
    $diskPercent = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1)
    Write-Host "  Disk (D:): ${diskPercent}%" -ForegroundColor $(if($diskPercent -gt 85){"Yellow"}else{"Green"})
    if ($diskPercent -gt 95) {
        $fixActions += @{action="log_cleanup"; reason="disk_critical"}
        $systemStatus.issuesFound++
    } elseif ($diskPercent -gt 85) {
        # Disk warning but not critical yet
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

# Check for timeout errors and fix them
Write-Host "[5/5] Checking for timeout errors..." -ForegroundColor Yellow
try {
    $jobs = openclaw cron list --json 2>$null | ConvertFrom-Json
    foreach ($job in $jobs) {
        if ($job.state.lastStatus -eq "error") {
            $lastError = $job.state.lastError
            if ($lastError -match "timeout" -or $lastError -match "execution timed out") {
                $oldTimeout = $job.payload.timeoutSeconds
                $newTimeout = [math]::Round($oldTimeout * 1.5)
                Write-Host "  ⚠️ Timeout error in '$($job.name)': $lastError" -ForegroundColor Yellow
                Write-Host "    → Increasing timeout from ${oldTimeout}s to ${newTimeout}s" -ForegroundColor Cyan
                
                $fixActions += @{
                    action = "update_timeout"
                    jobId = $job.id
                    jobName = $job.name
                    oldTimeout = $oldTimeout
                    newTimeout = $newTimeout
                }
                $systemStatus.issuesFound++
            } elseif ($lastError -match "Unknown model") {
                Write-Host "  ⚠️ Model error in '$($job.name)' - need config fix" -ForegroundColor Yellow
                $fixActions += @{
                    action = "model_error"
                    jobId = $job.id
                    jobName = $job.name
                    reason = "Model configuration issue - manual fix required"
                }
                $systemStatus.issuesFound++
            } elseif ($lastError -match "No available auth profile") {
                Write-Host "  ⚠️ Auth cooldown error in '$($job.name)'" -ForegroundColor Yellow
                $fixActions += @{
                    action = "auth_cooldown"
                    jobId = $job.id
                    jobName = $job.name
                }
                $systemStatus.issuesFound++
            }
        }
    }
} catch {
    Write-Host "  Error checking jobs: $($_.Exception.Message)" -ForegroundColor Red
}

# Execute fixes
Write-Host "[6/5] Executing fixes..." -ForegroundColor Yellow
if ($fixActions.Count -eq 0) {
    Write-Host "  OK No fixes needed" -ForegroundColor Green
} else {
    foreach ($action in $fixActions) {
        if ($DryRun) {
            Write-Host "  [DRY] $($action.action)" -ForegroundColor Cyan
        } else {
            Write-Host "  -> $($action.action)" -ForegroundColor Yellow
            if ($action.action -eq "update_timeout") {
                # Update timeout in cron job
                $patch = @{
                    payload = @{
                        timeoutSeconds = $action.newTimeout
                    }
                }
                openclaw cron update --id $($action.jobId) --patch ($patch | ConvertTo-Json -Compress) | Out-Null
                Write-Host "    ✓ Updated timeout: $($action.jobName)" -ForegroundColor Green
            }
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
