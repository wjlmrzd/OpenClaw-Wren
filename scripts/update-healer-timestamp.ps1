$f = 'D:\OpenClaw\.openclaw\workspace\memory\auto-healer-state.json'
$j = Get-Content $f -Raw | ConvertFrom-Json
$j.lastCheck = '2026-04-07T21:17:00+08:00'
$j.lastCheckResults.timestamp = '2026-04-07T21:17:00+08:00'
$j | ConvertTo-Json -Depth 10 | Set-Content $f -Encoding UTF8
Write-Host "Updated"
