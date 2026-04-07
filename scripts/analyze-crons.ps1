$jobs = Get-Content  -Encoding UTF8 -Path 'D:\OpenClaw\.openclaw\workspace\memory\cron-jobs.json' -Raw | ConvertFrom-Json
$all = $jobs.jobs
$now = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
$active = $all | Where-Object { $_.enabled -ne $false }

Write-Host "=== CRON ANALYZER ===" -ForegroundColor Cyan
Write-Host "Total: $($all.Count) | Active: $($active.Count)" -ForegroundColor White

# Status breakdown
$statusGroups = $active | Group-Object { $_.state.lastStatus } | ForEach-Object {
    @{ status = $_.Name; count = $_.Count }
}
Write-Host "`nBy status:" -ForegroundColor Yellow
$statusGroups | ForEach-Object { Write-Host "  $($_.status): $($_.count)" -ForegroundColor White }

# Error jobs
$errors = $active | Where-Object { $_.state.lastStatus -eq 'error' }
Write-Host "`nError jobs ($($errors.Count)):" -ForegroundColor Red
$errors | ForEach-Object {
    $ageMs = $now - ($_.state.lastRunAtMs)
    $ageH = [Math]::Round($ageMs / 3600000, 1)
    Write-Host "  $($_.name) | age=${ageH}h | lastRun=$(if($_.state.lastRunAtMs){(New-Object DateTime($_.state.lastRunAtMs)).ToString('MM-dd HH:mm')}else{'never'}) | id=$($_.id)"
}

# Timeout jobs
$timeouts = $active | Where-Object { $_.state.lastStatus -eq 'timeout' }
Write-Host "`nTimeout jobs ($($timeouts.Count)):" -ForegroundColor Magenta
$timeouts | ForEach-Object {
    $ageMs = $now - ($_.state.lastRunAtMs)
    $ageH = [Math]::Round($ageMs / 3600000, 1)
    Write-Host "  $($_.name) | age=${ageH}h | lastRun=$(if($_.state.lastRunAtMs){(New-Object DateTime($_.state.lastRunAtMs)).ToString('MM-dd HH:mm')}else{'never'}) | id=$($_.id)"
}

# Stale (>12h no run)
$stale = $active | Where-Object {
    if (-not $_.state.lastRunAtMs) { return $false }
    return ($now - $_.state.lastRunAtMs) -gt (12 * 3600000)
}
Write-Host "`nStale jobs >12h ($($stale.Count)):" -ForegroundColor DarkYellow
$stale | ForEach-Object {
    $ageMs = $now - ($_.state.lastRunAtMs)
    $ageH = [Math]::Round($ageMs / 3600000, 1)
    Write-Host "  $($_.name) | age=${ageH}h | lastRun=$(if($_.state.lastRunAtMs){(New-Object DateTime($_.state.lastRunAtMs)).ToString('MM-dd HH:mm')}else{'never'}) | status=$($_.state.lastStatus)"
}

# Quick summary: by schedule kind and name
Write-Host "`nActive jobs by schedule:" -ForegroundColor Cyan
$active | ForEach-Object {
    $schedule = $_.schedule.kind
    $expr = if ($_.schedule.expr) { $_.schedule.expr } elseif ($_.schedule.everyMs) { "$($_.schedule.everyMs)ms" } else { '?' }
    $timeout = $_.payload.timeoutSeconds
    Write-Host "  [$($_.state.lastStatus)] $expr | $($_.name) | timeout=${timeout}s | id=$($_.id)"
} | Sort-Object
