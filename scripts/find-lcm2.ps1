# Check agents directory for summaries and LCM data
Write-Host "=== agents/main ==="
Get-ChildItem "D:\OpenClaw\.openclaw\agents\main" -ErrorAction SilentlyContinue | Select-Object Name
Write-Host ""
Write-Host "=== agents/main/sessions ==="
Get-ChildItem "D:\OpenClaw\.openclaw\agents\main\sessions" -ErrorAction SilentlyContinue | Where-Object { $_.Extension -match "json|db|sqlite|bin" } | Select-Object Name, Length, LastWriteTime
Write-Host ""
Write-Host "=== Lossless-Claw dist ==="
Get-ChildItem "D:\OpenClaw\.openclaw\workspace\plugins-lossless-claw-enhanced\dist" -ErrorAction SilentlyContinue | Select-Object Name, Length
Write-Host ""
Write-Host "=== Lossless-Claw data dir ==="
Get-ChildItem "D:\OpenClaw\.openclaw\workspace\plugins-lossless-claw-enhanced\data" -ErrorAction SilentlyContinue | Select-Object Name, Length, LastWriteTime
