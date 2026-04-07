$s = Get-Content 'D:\OpenClaw\.openclaw\workspace\memory\notification-state.json' -Raw -Encoding UTF8 | ConvertFrom-Json
$s.current_time_period = 'evening'
$s.last_check = '2026-04-04T18:45:00+08:00'
$s.last_updated = '2026-04-04T18:45:00+08:00'
$s | ConvertTo-Json -Depth 5 | Set-Content 'D:\OpenClaw\.openclaw\workspace\memory\notification-state.json' -Encoding UTF8
