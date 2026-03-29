$ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$line = "[$ts] [WARNING] [resource-guard] Disk alert: C=drive 100pct full, H=drive 85.1pct | mem=66.8pct gw_rss_mb=1690"
[System.IO.File]::AppendAllText("D:\OpenClaw\.openclaw\workspace\memory\events.log", "`n$line")
Write-Host "Logged: $line"
