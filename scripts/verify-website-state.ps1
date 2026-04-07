$path = "D:\OpenClaw\.openclaw\workspace\scripts\website-monitor-state.json"
try {
    $data = Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json
    Write-Host "website-monitor-state.json: OK ($($data.PSObject.Properties.Count) sites)"
} catch {
    Write-Host "website-monitor-state.json: FAILED $($_.Exception.Message)"
}
