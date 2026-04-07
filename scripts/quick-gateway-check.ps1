$port = 18789
$conn = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
if ($conn) {
    $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
    if ($proc) {
        $memMB = [math]::Round($proc.WorkingSet64 / 1MB, 1)
        $startTime = $proc.StartTime.ToString("yyyy-MM-dd HH:mm:ss")
        $uptime = ((Get-Date) - $proc.StartTime).ToString("hh\:mm\:ss")
        Write-Output "PID=$($proc.Id) MemoryMB=$memMB StartTime=$startTime Uptime=$uptime"
    } else {
        Write-Output "PORT_FOUND_NO_PROC"
    }
} else {
    Write-Output "PORT_NOT_LISTENING"
}
