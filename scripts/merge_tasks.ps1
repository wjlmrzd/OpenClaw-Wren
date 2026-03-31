$path = "D:\OpenClaw\.openclaw\cron\jobs.json"
$json = Get-Content $path -Raw | ConvertFrom-Json

$ids = @(
    "f920c2a2-6afc-4fc8-84ad-01593d2d22d1",
    "7eb7f35e-fe72-4a90-bfc6-ed59392b10f6",
    "2b564e59-8ed9-4cd8-8345-a9b41e4349bb"
)

foreach ($job in $json.jobs) {
    if ($ids -contains $job.id) {
        $job.enabled = $false
        $job.updatedAtMs = [int64](Get-Date).ToUniversalTime().Subtract([DateTime]::new(1970,1,1)).TotalMilliseconds
        Write-Host "Disabled: $($job.id.Substring(0,8))"
    }
}

$json | ConvertTo-Json -Depth 20 | Set-Content $path -Encoding UTF8
Write-Host "Done"
