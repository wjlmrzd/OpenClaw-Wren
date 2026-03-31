try {
    $resp = Invoke-RestMethod -Uri 'http://localhost:18789/health' -TimeoutSec 5
    $resp | ConvertTo-Json
    exit 0
} catch {
    Write-Host "Gateway unreachable: $($_.Exception.Message)"
    exit 1
}
