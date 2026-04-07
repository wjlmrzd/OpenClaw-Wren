$data = Get-Content 'D:\OpenClaw\.openclaw\workspace\cron\jobs.json' -Raw | ConvertFrom-Json
$targetIds = @('53b6edc8-7cc6-4900-ab41-d1abd3e1e15f','7eb7f35e-fe72-4a90-bfc6-ed59392b10f6','9f4f1914-3bbf-46e9-8ad4-30547e66998b')
foreach ($j in $data.jobs) {
    if ($targetIds -contains $j.id) {
        Write-Host "=== $($j.name) ==="
        $j | ConvertTo-Json -Depth 10
        Write-Host ""
    }
}
