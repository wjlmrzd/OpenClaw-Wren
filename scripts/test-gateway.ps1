# Test Gateway connectivity
$ErrorActionPreference = 'Stop'

try {
    $response = Invoke-WebRequest -Uri 'http://127.0.0.1:18789/' -TimeoutSec 3 -UseBasicParsing
    Write-Host "Gateway responds: $($response.StatusCode)"
    exit 0
} catch {
    Write-Host "Gateway error: $($_.Exception.Message)"
    exit 1
}
