$jobsPath = "D:\OpenClaw\.openclaw\cron\jobs.json"
$jobs = Get-Content $jobsPath -Raw -Encoding UTF8 | ConvertFrom-Json

$enabled = 0
foreach ($job in $jobs.jobs) {
    if (-not $job.enabled) {
        $job.enabled = $true
        $enabled++
        Write-Host "Re-enabled: $($job.name)"
    }
}

$jobs | ConvertTo-Json -Depth 10 | Set-Content $jobsPath -Encoding UTF8
Write-Host "Total re-enabled: $enabled"
