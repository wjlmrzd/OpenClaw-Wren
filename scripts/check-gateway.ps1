try {
    $headers = @{'Authorization' = 'Bearer ' + $env:GATEWAY_AUTH_TOKEN}
    $response = Invoke-WebRequest -Uri 'http://localhost:18789/api/status' -TimeoutSec 5 -Headers $headers -UseBasicParsing
    Write-Host "Status:" $response.StatusCode
} catch {
    $status = $_.Exception.Response.StatusCode
    Write-Host "Status Code:" $status
}
