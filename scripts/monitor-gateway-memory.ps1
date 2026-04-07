# Memory Monitor for OpenClaw Gateway
# Records memory usage to memory/gateway-memory.log for trend analysis

$LogFile = "D:\OpenClaw\.openclaw\workspace\memory\gateway-memory.log"
$ThresholdMB = 400  # Alert threshold in MB

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Get Node.js processes
$nodeProcs = Get-Process -Name node -ErrorAction SilentlyContinue | Where-Object { $_.Id -ne $null }

if ($nodeProcs) {
    $totalMemory = 0
    foreach ($proc in $nodeProcs) {
        $memMB = [math]::Round($proc.WorkingSet64 / 1MB, 2)
        $totalMemory += $memMB
    }
    
    $totalMemory = [math]::Round($totalMemory, 2)
    
    # Log to file
    $logEntry = "$timestamp | Gateway Memory: ${totalMemory}MB | Threshold: ${ThresholdMB}MB"
    Add-Content -Path $LogFile -Value $logEntry
    
    # Output for cron job reporting
    Write-Host "Gateway Memory: ${totalMemory}MB"
    
    # Alert if threshold exceeded
    if ($totalMemory -gt $ThresholdMB) {
        Write-Host "WARNING: Memory exceeds ${ThresholdMB}MB threshold!"
        exit 1
    }
} else {
    Write-Host "No Gateway process found"
}