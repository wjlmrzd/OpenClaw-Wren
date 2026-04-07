$lines = Get-Content 'D:\OpenClaw\.openclaw\workspace\scripts\gateway-monitor.ps1'
for($i = 60; $i -lt [Math]::Min(100, $lines.Count); $i++) {
    $ln = $i + 1
    Write-Host "$ln`: $($lines[$i])"
}
