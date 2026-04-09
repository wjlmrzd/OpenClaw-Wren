$cfg = Get-Content 'D:\OpenClaw\.openclaw\openclaw.json' -Raw | ConvertFrom-Json
Write-Host "lastTouchedAt: $($cfg.lastTouchedAt)"
Write-Host "version: $($cfg.version)"
Write-Host "logLevel: $($cfg.logLevel)"
Write-Host "agents count: $($cfg.agents.Count)"
Write-Host "plugins count: $($cfg.plugins.Count)"
$channelNames = $cfg.channels.PSObject.Properties.Name
Write-Host "channels: $($channelNames -join ', ')"

Write-Host ""
Write-Host "=== CRON JOBS ==="
$j = Get-Content 'D:\OpenClaw\.openclaw\cron\jobs.json' -Raw | ConvertFrom-Json
Write-Host "Total jobs: $($j.jobs.Count)"
$enabled = ($j.jobs | Where-Object { $_.enabled -ne $false }).Count
Write-Host "Enabled: $enabled"
Write-Host "Last 5:"
foreach ($job in ($j.jobs | Select-Object -Last 5)) {
    Write-Host "  $($job.id) [$($job.name)] enabled=$($job.enabled)"
}

Write-Host ""
Write-Host "=== DIFF vs LAST BACKUP ==="
$lastBackup = Get-ChildItem 'D:\OpenClaw\.openclaw\memory\config-backups' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($lastBackup) {
    Write-Host "Last backup: $($lastBackup.Name) ($($lastBackup.LastWriteTime))"
    $diff = (Get-Content 'D:\OpenClaw\.openclaw\openclaw.json' -Raw) -ne (Get-Content $lastBackup.FullName -Raw)
    if ($diff) { Write-Host "openclaw.json HAS CHANGED vs last backup" } else { Write-Host "openclaw.json UNCHANGED vs last backup" }
} else {
    Write-Host "No backups found"
}
