[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$data = [System.IO.File]::ReadAllText("D:\OpenClaw\.openclaw\workspace\cron\jobs.json", [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$jobs = $data.jobs
Write-Host ("Total jobs: " + $jobs.Count)
Write-Host ""
foreach ($j in $jobs) {
    Write-Host $j.name
}
