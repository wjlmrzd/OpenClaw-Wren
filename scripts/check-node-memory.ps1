# Check Node.js (Gateway) memory usage
$nodeProcs = Get-Process -Name node -ErrorAction SilentlyContinue
if ($nodeProcs) {
    foreach ($p in $nodeProcs) {
        $memMB = [math]::Round($p.WorkingSet64 / 1MB, 2)
        $privMB = [math]::Round($p.PrivateMemorySize64 / 1MB, 2)
        $cpu = [math]::Round($p.CPU, 2)
        Write-Host "PID=$($p.Id) WorkingSet=${memMB}MB Private=${privMB}MB CPU=${cpu}s"
    }
} else {
    Write-Host "No node process found"
}

# System memory
$os = Get-CimInstance Win32_OperatingSystem
$totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedGB = [math]::Round($totalGB - $freeGB, 2)
$pct = [math]::Round($usedGB / $totalGB * 100, 1)
Write-Host "System: ${usedGB}GB / ${totalGB}GB (${pct}%)"
