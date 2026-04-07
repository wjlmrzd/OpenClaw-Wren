$data = Get-Content 'D:\OpenClaw\.openclaw\workspace\cron\jobs.json' -Raw | ConvertFrom-Json
# Find jobs with */30 schedule
$target = $data.jobs | Where-Object { $_.schedule.expr -eq '*/30 * * * *' }
foreach ($j in $target) {
    Write-Host "Name (bytes): $([BitConverter]::ToString([System.Text.Encoding]::UTF8.GetBytes($j.name)))"
    Write-Host "Name (default): $($j.name)"
    Write-Host "ID: $($j.id)"
    Write-Host "Enabled: $($j.enabled)"
    Write-Host "Payload message: $($j.payload.message)"
    Write-Host ""
}
