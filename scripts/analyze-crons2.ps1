$file = 'D:\OpenClaw\.openclaw\workspace\memory\cron-jobs.json'
$content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
$jobs = $content | ConvertFrom-Json
$all = $jobs.jobs
$now = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
$active = $all | Where-Object { $_.enabled -ne $false }

Write-Host "Total: $($all.Count) | Active: $($active.Count)"

$statusGroups = $active | Group-Object { $_.state.lastStatus } | ForEach-Object {
    "$($_.Name): $($_.Count)"
}
Write-Host "By status: $($statusGroups -join ', ')"

$errors = $active | Where-Object { $_.state.lastStatus -eq 'error' }
Write-Host "`nERROR jobs ($($errors.Count)):"
$errors | ForEach-Object {
    $ageMs = $now - ($_.state.lastRunAtMs)
    $ageH = [Math]::Round($ageMs / 3600000, 1)
    $lastRun = if($_.state.lastRunAtMs){(New-Object DateTime($_.state.lastRunAtMs)).ToString('MM-dd HH:mm')}else{'never'}
    Write-Host "  $($_.name) | lastRun=$lastRun | age=${ageH}h | id=$($_.id)"
}

$timeouts = $active | Where-Object { $_.state.lastStatus -eq 'timeout' }
Write-Host "`nTIMEOUT jobs ($($timeouts.Count)):"
$timeouts | ForEach-Object {
    $ageMs = $now - ($_.state.lastRunAtMs)
    $ageH = [Math]::Round($ageMs / 3600000, 1)
    $lastRun = if($_.state.lastRunAtMs){(New-Object DateTime($_.state.lastRunAtMs)).ToString('MM-dd HH:mm')}else{'never'}
    Write-Host "  $($_.name) | lastRun=$lastRun | age=${ageH}h | id=$($_.id)"
}

$stale = $active | Where-Object {
    if (-not $_.state.lastRunAtMs) { return $false }
    return ($now - $_.state.lastRunAtMs) -gt (12 * 3600000)
}
Write-Host "`nSTALE jobs >12h ($($stale.Count)):"
$stale | ForEach-Object {
    $ageMs = $now - ($_.state.lastRunAtMs)
    $ageH = [Math]::Round($ageMs / 3600000, 1)
    $lastRun = if($_.state.lastRunAtMs){(New-Object DateTime($_.state.lastRunAtMs)).ToString('MM-dd HH:mm')}else{'never'}
    Write-Host "  $($_.name) | lastRun=$lastRun | age=${ageH}h | status=$($_.state.lastStatus)"
}

Write-Host "`nAll active jobs by schedule:"
$active | ForEach-Object {
    $expr = if ($_.schedule.expr) { $_.schedule.expr } elseif ($_.schedule.everyMs) { "$($_.schedule.everyMs)ms" } else { '?' }
    $timeout = $_.payload.timeoutSeconds
    $status = $_.state.lastStatus
    Write-Host "  [$status] $expr | $($_.name) | t=$($timeout)s | id=$($_.id)"
}
