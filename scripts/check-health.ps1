try {
    $r = Invoke-WebRequest -Uri 'http://127.0.0.1:18789/health' -TimeoutSec 5 -UseBasicParsing
    Write-Host "HTTP_OK:$($r.StatusCode)"
} catch {
    Write-Host "HTTP_ERROR:$($_.Exception.Message)"
}
