# check-system-resources.ps1 - System resource monitor with auto cleanup
# UTF-8 with BOM - Trigger C drive cleanup when usage > 90%

param(
    [string]$OutputPath = "D:\OpenClaw\.openclaw\workspace\memory\system-resources-report.json",
    [switch]$AutoCleanup  # Auto trigger cleanup when C drive > 90%
)

$ErrorActionPreference = "Continue"
$report = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    drives = @{}
    memory = @{}
    actions = @()
    alerts = @()
}

# ========================================
# 1. Check C Drive
# ========================================
try {
    $cDrive = Get-Volume -DriveLetter C -ErrorAction Stop
    $cTotal = $cDrive.Size
    $cFree = $cDrive.SizeRemaining
    $cUsedPercent = [math]::Round(($cTotal - $cFree) / $cTotal * 100, 1)
    
    $report.drives.C = @{
        totalGB = [math]::Round($cTotal / 1GB, 2)
        freeGB = [math]::Round($cFree / 1GB, 2)
        usedGB = [math]::Round(($cTotal - $cFree) / 1GB, 2)
        usedPercent = $cUsedPercent
    }
    
    Write-Host "C Drive: $($report.drives.C.usedPercent)% used ($($report.drives.C.freeGB) GB free)"
    
    # C drive alerts
    if ($cUsedPercent -ge 90) {
        $alert = "CRITICAL: C drive usage $($cUsedPercent)% exceeds 90% threshold"
        $report.alerts += $alert
        Write-Host $alert -ForegroundColor Red
        
        # Auto cleanup trigger
        if ($AutoCleanup -or $cUsedPercent -ge 95) {
            Write-Host "Triggering C drive cleanup..." -ForegroundColor Yellow
            $cleanupScript = "D:\OpenClaw\.openclaw\workspace\scripts\clean-c-drive.ps1"
            
            if (Test-Path $cleanupScript) {
                try {
                    & powershell -ExecutionPolicy Bypass -File $cleanupScript
                    $report.actions += "Executed clean-c-drive.ps1"
                    Write-Host "C drive cleanup completed" -ForegroundColor Green
                    
                    # Re-check after cleanup
                    $cDriveAfter = Get-Volume -DriveLetter C
                    $cFreeAfter = $cDriveAfter.SizeRemaining
                    $cUsedAfter = [math]::Round(($cDriveAfter.Size - $cFreeAfter) / $cDriveAfter.Size * 100, 1)
                    
                    $report.drives.C.afterCleanup = @{
                        usedPercent = $cUsedAfter
                        freeGB = [math]::Round($cFreeAfter / 1GB, 2)
                    }
                    
                    $freedGB = [math]::Round(($cFreeAfter - $cFree) / 1GB, 2)
                    $report.actions += "Freed $freedGB GB on C drive"
                    Write-Host "Freed: $freedGB GB (now $($cUsedAfter)% used)" -ForegroundColor Green
                    
                } catch {
                    $report.actions += "Cleanup failed: $($_.Exception.Message)"
                    Write-Host "Cleanup failed: $($_.Exception.Message)" -ForegroundColor Red
                }
            } else {
                $report.actions += "Cleanup script not found: $cleanupScript"
                Write-Host "Cleanup script not found" -ForegroundColor Red
            }
        }
    } elseif ($cUsedPercent -ge 85) {
        $alert = "WARNING: C drive usage $($cUsedPercent)% exceeds 85%"
        $report.alerts += $alert
        Write-Host $alert -ForegroundColor Yellow
    }
    
} catch {
    $report.drives.C = @{ error = "Cannot get C drive info: $($_.Exception.Message)" }
    Write-Host "ERROR: Cannot get C drive info" -ForegroundColor Red
}

# ========================================
# 2. Check D Drive
# ========================================
try {
    $dDrive = Get-Volume -DriveLetter D -ErrorAction Stop
    $dTotal = $dDrive.Size
    $dFree = $dDrive.SizeRemaining
    $dUsedPercent = [math]::Round(($dTotal - $dFree) / $dTotal * 100, 1)
    
    $report.drives.D = @{
        totalGB = [math]::Round($dTotal / 1GB, 2)
        freeGB = [math]::Round($dFree / 1GB, 2)
        usedGB = [math]::Round(($dTotal - $dFree) / 1GB, 2)
        usedPercent = $dUsedPercent
    }
    
    Write-Host "D Drive: $($report.drives.D.usedPercent)% used ($($report.drives.D.freeGB) GB free)"
    
    if ($dUsedPercent -ge 90) {
        $alert = "CRITICAL: D drive usage $($dUsedPercent)% exceeds 90%"
        $report.alerts += $alert
        Write-Host $alert -ForegroundColor Red
    } elseif ($dUsedPercent -ge 85) {
        $alert = "WARNING: D drive usage $($dUsedPercent)% exceeds 85%"
        $report.alerts += $alert
        Write-Host $alert -ForegroundColor Yellow
    }
    
} catch {
    $report.drives.D = @{ error = "Cannot get D drive info: $($_.Exception.Message)" }
    Write-Host "ERROR: Cannot get D drive info" -ForegroundColor Red
}

# ========================================
# 3. Check Memory Usage
# ========================================
try {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $memTotal = $os.TotalVisibleMemorySize * 1KB
    $memFree = $os.FreePhysicalMemory * 1KB
    $memUsedPercent = [math]::Round(($memTotal - $memFree) / $memTotal * 100, 1)
    
    $report.memory = @{
        totalGB = [math]::Round($memTotal / 1GB, 2)
        freeGB = [math]::Round($memFree / 1GB, 2)
        usedGB = [math]::Round(($memTotal - $memFree) / 1GB, 2)
        usedPercent = $memUsedPercent
    }
    
    Write-Host "Memory: $($report.memory.usedPercent)% used ($($report.memory.freeGB) GB free)"
    
    if ($memUsedPercent -ge 90) {
        $alert = "CRITICAL: Memory usage $($memUsedPercent)% exceeds 90%"
        $report.alerts += $alert
        Write-Host $alert -ForegroundColor Red
    } elseif ($memUsedPercent -ge 85) {
        $alert = "WARNING: Memory usage $($memUsedPercent)% exceeds 85%"
        $report.alerts += $alert
        Write-Host $alert -ForegroundColor Yellow
    }
    
} catch {
    $report.memory = @{ error = "Cannot get memory info: $($_.Exception.Message)" }
    Write-Host "ERROR: Cannot get memory info" -ForegroundColor Red
}

# ========================================
# 4. Summary
# ========================================
$report.summary = @{
    status = if ($report.alerts.Count -eq 0) { "OK" } elseif ($report.alerts -match "CRITICAL") { "CRITICAL" } else { "WARNING" }
    alertCount = $report.alerts.Count
    actionCount = $report.actions.Count
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "System Resources Check Complete" -ForegroundColor Cyan
Write-Host "Status: $($report.summary.status)" -ForegroundColor $(if ($report.summary.status -eq "OK") { "Green" } elseif ($report.summary.status -eq "CRITICAL") { "Red" } else { "Yellow" })
Write-Host "Alerts: $($report.alerts.Count) | Actions: $($report.actions.Count)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Save JSON report
$reportJson = $report | ConvertTo-Json -Depth 3
$reportJson | Out-File -FilePath $OutputPath -Encoding UTF8

# Return summary for cron agent
Write-Output "STATUS: $($report.summary.status)"
if ($report.alerts.Count -gt 0) {
    Write-Output "ALERTS: $($report.alerts -join '; ')"
}
if ($report.actions.Count -gt 0) {
    Write-Output "ACTIONS: $($report.actions -join '; ')"
}