$data = Get-Content 'D:\OpenClaw\.openclaw\workspace\cron\jobs.json' -Raw | ConvertFrom-Json
Write-Host "Total jobs in jobs.json: $($data.jobs.Count)"
Write-Host "Enabled: $($data.jobs.Where({$_.enabled}).Count)"
Write-Host "Disabled: $($data.jobs.Where({-not $_.enabled}).Count)"
Write-Host ""

# Find conflicting schedules
$grouped = $data.jobs | Group-Object { $_.schedule.expr }
foreach ($g in $grouped) {
    if ($g.Count -gt 1) {
        Write-Host "SCHEDULE CONFLICT: '$($g.Name)' - $($g.Count) jobs"
        foreach ($j in $g.Group) {
            Write-Host "  - $($j.name) (enabled: $($j.enabled))"
        }
        Write-Host ""
    }
}

# Check for jobs without model
$noModel = $data.jobs.Where({$_.payload.kind -eq 'agentTurn' -and -not $_.payload.model})
Write-Host "Jobs without explicit model: $($noModel.Count)"
foreach ($j in $noModel) {
    Write-Host "  - $($j.name)"
}
