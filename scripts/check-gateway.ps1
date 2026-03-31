try {
    $resp = Invoke-WebRequest -Uri 'http://localhost:18789/' -TimeoutSec 5
    Write-Host "Status: $($resp.StatusCode)"
    Write-Host "Content: $($resp.Content.Substring(0, [Math]::Min(500, $resp.Content.Length)))"
} catch {
    Write-Host "Gateway unreachable: $($_.Exception.Message)"
}
