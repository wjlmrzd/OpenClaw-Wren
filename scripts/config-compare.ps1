# Compare current openclaw.json with last backup
$current = Get-Content 'D:\OpenClaw\.openclaw\openclaw.json' -Raw
$backup = Get-Content 'D:\OpenClaw\.openclaw\memory\config-backups\openclaw-20260408-085000.json' -Raw

# Quick diff - check meta
Add-Type -AssemblyName System.Text.Json
$curr = [System.Text.Json.JsonDocument]::Parse($current)
$bkp = [System.Text.Json.JsonDocument]::Parse($backup)

# Get meta
$currMeta = $curr.RootElement.GetProperty("meta")
$bkpMeta = $bkp.RootElement.GetProperty("meta")

Write-Host "Current lastTouchedAt: $($currMeta.GetProperty('lastTouchedAt'))"
Write-Host "Backup lastTouchedAt: $($bkpMeta.GetProperty('lastTouchedAt'))"
Write-Host "Current version: $($currMeta.GetProperty('lastTouchedVersion'))"
Write-Host "Backup version: $($bkpMeta.GetProperty('lastTouchedVersion'))"

# Check logLevel
$currLog = $curr.RootElement.GetProperty("logLevel").GetString()
$bkpLog = $bkp.RootElement.GetProperty("logLevel").GetString()
Write-Host "Current logLevel: $currLog"
Write-Host "Backup logLevel: $bkpLog"

# Check agents count
$currAgents = $curr.RootElement.GetProperty("agents").GetArrayLength()
$bkpAgents = $bkp.RootElement.GetProperty("agents").GetArrayLength()
Write-Host "Current agents: $currAgents"
Write-Host "Backup agents: $bkpAgents"

# Check channels
if ($curr.RootElement.TryGetProperty("channels", [ref]$null)) {
    $currCh = $curr.RootElement.GetProperty("channels").EnumerateObject() | ForEach-Object { $_.Name }
    $bkpCh = $bkp.RootElement.GetProperty("channels").EnumerateObject() | ForEach-Object { $_.Name }
    Write-Host "Current channels: $($currCh -join ', ')"
    Write-Host "Backup channels: $($bkpCh -join ', ')"
}

# Check env
if ($curr.RootElement.TryGetProperty("env", [ref]$null)) {
    $envKeys = $curr.RootElement.GetProperty("env").EnumerateObject() | ForEach-Object { $_.Name }
    Write-Host "Env keys: $($envKeys -join ', ')"
}
if ($bkp.RootElement.TryGetProperty("env", [ref]$null)) {
    $envKeysBkp = $bkp.RootElement.GetProperty("env").EnumerateObject() | ForEach-Object { $_.Name }
    Write-Host "Backup env keys: $($envKeysBkp -join ', ')"
}

Write-Host ""
Write-Host "Size current: $($current.Length) bytes"
Write-Host "Size backup: $($backup.Length) bytes"
Write-Host "Size diff: $($current.Length - $backup.Length) bytes"
