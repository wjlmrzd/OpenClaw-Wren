$content = Get-Content 'D:\OpenClaw\.openclaw\cron\jobs.json' -Raw -Encoding UTF8
$jobs = $content | ConvertFrom-Json
$problematic = @('auto-healer\.ps1', 'knowledge-organizer\.ps1', 'regression-test-runner\.ps1')
$count = 0
foreach ($job in $jobs.jobs) {
    foreach ($p in $problematic) {
        if ($job.payload.message -match $p) {
            $job.enabled = $false
            $count++
            Write-Host "Disabled: $($job.name)"
            break
        }
    }
}
$output = $jobs | ConvertTo-Json -Depth 10
Set-Content 'D:\OpenClaw\.openclaw\cron\jobs.json' -Value $output -Encoding UTF8
Write-Host "Total disabled: $count"