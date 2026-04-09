$s = Get-Content 'D:\OpenClaw\.openclaw\workspace\memory\notification-state.json' -Encoding UTF8 | ConvertFrom-Json
$s.last_check = '2026-04-09T19:30:00+08:00'
$s | ConvertTo-Json -Depth 3 | Out-File 'D:\OpenClaw\.openclaw\workspace\memory\notification-state.json' -Encoding UTF8
