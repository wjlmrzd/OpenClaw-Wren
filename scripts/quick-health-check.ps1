# Quick Health Check
$ErrorActionPreference = "Continue"
$results = @{}
$results.timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$results.issues = @()
$openclawRoot = "D:\OpenClaw\.openclaw"
$cronJobsPath = Join-Path $openclawRoot "cron\jobs.json"

# Gateway
try {
    $null = & openclaw gateway status 2>$null
    if ($LASTEXITCODE -eq 0) {
        $results.gateway = "OK"
    } else {
        $results.gateway = "Error:$LASTEXITCODE"
        $results.issues += "Gateway error"
    }
} catch {
    $results.gateway = "Error"
    $results.issues += "Gateway failed"
}

# Cron（直接读 jobs.json 避免 cron list 超时）
try {
    $jobsJson = [System.IO.File]::ReadAllText($cronJobsPath, [System.Text.Encoding]::UTF8)
    $jobsData = $jobsJson | ConvertFrom-Json
    $allJobs = $jobsData.jobs
    $failed = @()
    foreach ($j in $allJobs) {
        if ($j.status -eq 'error') {
            $failed += $j
        }
    }
    $results.cronTotal = $allJobs.Count
    $results.cronFailed = $failed.Count
    $results.cronFailedJobs = $failed
    if ($failed.Count -gt 0) { $results.issues += "$($failed.Count) cron errors" }
} catch {
    $results.cronError = $_.Exception.Message
    $results.issues += "Cron check failed"
}

# Memory
try {
    $nodeMem = (Get-Process -Name node -ErrorAction SilentlyContinue | Measure-Object WorkingSet64 -Sum).Sum / 1GB
    $results.memUsedGB = [math]::Round($nodeMem, 1)
    $results.memTotalGB = 16
    $results.memPct = [math]::Round($nodeMem / 16 * 100, 1)
    if ($results.memPct -gt 85) { $results.issues += "Memory:$($results.memPct)%" }
} catch {
    $results.issues += "Memory check failed"
}

# Disk
try {
    $drv = Get-PSDrive -Name C -ErrorAction SilentlyContinue
    $results.diskFreeGB = [math]::Round($drv.Free / 1GB, 1)
    $results.diskTotalGB = [math]::Round(($drv.Free + $drv.Used) / 1GB, 1)
    $results.diskPct = [math]::Round($drv.Used / ($drv.Free + $drv.Used) * 100, 1)
    if ($results.diskPct -gt 90) { $results.issues += "Disk:$($results.diskPct)%" }
} catch {
    $results.issues += "Disk check failed"
}

# Summary
Write-Host "=== Quick Health Check ==="
Write-Host "Time: $($results.timestamp)"
Write-Host "Gateway: $($results.gateway)"
Write-Host "Cron: $($results.cronTotal) total, $($results.cronFailed) failed"
foreach ($j in $results.cronFailedJobs) {
    $n = if ($j.name) { $j.name } else { $j.id }
    Write-Host "  FAIL: $n | $($j.lastError)"
}
Write-Host "Memory: $($results.memUsedGB)GB / $($results.memTotalGB)GB ($($results.memPct)%)"
Write-Host "Disk: $($results.diskFreeGB)GB free / $($results.diskTotalGB)GB ($($results.diskPct)%)"
if ($results.issues.Count -eq 0) {
    Write-Host "STATUS: HEALTHY"
} else {
    Write-Host "STATUS: ISSUES: $($results.issues -join '; ')"
}

$results | ConvertTo-Json -Depth 4
