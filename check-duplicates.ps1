$data = Get-Content 'D:\OpenClaw\.openclaw\workspace\cron\jobs.json' -Raw | ConvertFrom-Json
$enabled = $data.jobs | Where-Object { $_.enabled -eq $true }
$grouped = $enabled | Group-Object { $_.schedule.expr }
$conflicts = $grouped | Where-Object { $_.Count -gt 1 }
if ($conflicts.Count -eq 0) {
    Write-Host "No duplicate schedules found. Good!"
} else {
    foreach ($g in $conflicts) {
        Write-Host "Schedule '$($g.Name)' has $($g.Count) jobs:"
        foreach ($j in $g.Group) {
            Write-Host "  - $($j.name)"
        }
        Write-Host ""
    }
}
Write-Host "Total enabled jobs: $($enabled.Count)"
