# Quick Gateway Health Check
$ErrorActionPreference = 'SilentlyContinue'
$results = @{
    time = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    gateway = 'unknown'
    memory = $null
    disk_C = $null
    disk_H = $null
    node_processes = $null
    openclaw_running = $false
}

# Gateway HTTP check
try {
    $resp = Invoke-RestMethod -Uri 'http://127.0.0.1:18789/health' -TimeoutSec 5 -ErrorAction Stop
    $results.gateway = 'ok'
    $results.gateway_detail = $resp
} catch {
    $statusCode = $_.Exception.Response.StatusCode
    if ($statusCode) {
        $results.gateway = "http_error_$statusCode"
    } else {
        $results.gateway = 'connection_failed'
    }
}

# Process check
$nodeProcs = Get-Process -Name 'node' -ErrorAction SilentlyContinue
if ($nodeProcs) {
    $results.node_processes = $nodeProcs.Count
    $results.openclaw_running = $true
    $totalMemGB = ($nodeProcs | Measure-Object WorkingSet64 -Sum).Sum / 1GB
    $results.memory_gb = [math]::Round($totalMemGB, 2)
}

# Disk usage
try {
    $volC = Get-Volume -DriveLetter 'C' -ErrorAction Stop
    if ($volC.Size) {
        $results.disk_C = [math]::Round(($volC.Size - $volC.SizeRemaining) / $volC.Size * 100, 1)
    }
} catch {}
try {
    $volH = Get-Volume -DriveLetter 'H' -ErrorAction Stop
    if ($volH.Size) {
        $results.disk_H = [math]::Round(($volH.Size - $volH.SizeRemaining) / $volH.Size * 100, 1)
    }
} catch {}

ConvertTo-Json -Compress $results
