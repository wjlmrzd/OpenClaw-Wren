$jobsFile = "D:\OpenClaw\.openclaw\workspace\cron\jobs.json"
$jobs = Get-Content $jobsFile -Raw | ConvertFrom-Json
$newModel = "minimax-coding-plan/minimax-2.7"
$count = 0

foreach ($job in $jobs.jobs) {
    if ($job.payload -and $job.payload.model) {
        $oldModel = $job.payload.model
        $job.payload.model = $newModel
        $count++
        Write-Host "[$count] $($job.name): $oldModel -> $newModel"
    }
}

$jobs | ConvertTo-Json -Depth 20 | Set-Content $jobsFile -Encoding UTF8
Write-Host ""
Write-Host "Total updated: $count jobs"
Write-Host "Backup saved to: memory\model-backup-2026-03-29.json"
