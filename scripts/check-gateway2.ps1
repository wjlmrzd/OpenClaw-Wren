try {
    $r = Invoke-WebRequest -Uri 'http://localhost:18789/' -TimeoutSec 3
    Write-Host "Gateway Status: $($r.StatusCode)"
    Write-Host "Content: $($r.Content.Substring(0, [Math]::Min(200, $r.Content.Length)))")
} catch {
    Write-Host "Gateway Error: $($_.Exception.Message)"
}
