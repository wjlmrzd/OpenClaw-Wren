$json = Get-Content "D:\OpenClaw\.openclaw\workspace\memory\cron-list.json" -Raw -Encoding UTF8
$data = $json | ConvertFrom-Json
$jobs = $data.jobs
Write-Host "=== Cron Jobs Summary ===" 
Write-Host "Total: $($jobs.Count)"
Write-Host ""
$jobs | ForEach-Object { 
    $status = if ($_.state.consecutiveErrors -gt 0) { "ERROR($($_.state.consecutiveErrors))" } else { "OK" }
    $next = if ($_.state.nextRunAtMs) { [DateTimeOffset]::FromUnixTimeMilliseconds($_.state.nextRunAtMs).ToString("MM-dd HH:mm") } else { "N/A" }
    Write-Host "$($_.name) | $($_.schedule.expr) | $status | Next: $next"
}
