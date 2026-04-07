$jobsPath = "D:\OpenClaw\.openclaw\workspace\cron\jobs.json"
$jobs = Get-Content $jobsPath -Raw -Encoding UTF8 | ConvertFrom-Json
Write-Host "Total jobs: $($jobs.jobs.Count)"
$jobs.jobs | Select-Object -First 5 | ForEach-Object { Write-Host $_.name }
