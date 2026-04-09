$client = New-Object System.Net.Sockets.TcpClient
try {
    $client.Connect('127.0.0.1', 18789)
    $client.Close()
    Write-Host 'PORT_OPEN'
} catch {
    Write-Host 'PORT_CLOSED'
}
