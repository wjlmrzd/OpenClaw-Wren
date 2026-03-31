$json = Get-Content 'D:\OpenClaw\.openclaw\cron\jobs.json' -Raw -Encoding UTF8 | ConvertFrom-Json
$disabled = $json.jobs | Where-Object { $_.enabled -eq $false }
$healthJob = $json.jobs | Where-Object { $_.id -eq '92af6946-b23b-4534-a6b8-5877cfa36f12' }

Write-Host "=== VERIFICATION ==="
Write-Host "Total jobs: $($json.jobs.Count)"
Write-Host "Enabled: $($json.jobs.Count - $disabled.Count)"
Write-Host "Disabled: $($disabled.Count)"
Write-Host ""
Write-Host "Health monitor schedule: $($healthJob.schedule.expr)"
Write-Host ""
Write-Host "Disabled jobs:"
foreach ($j in $disabled) {
    Write-Host "  $($j.id) : $($j.name)"
}
