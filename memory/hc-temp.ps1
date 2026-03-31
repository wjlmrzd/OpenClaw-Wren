$ErrorActionPreference = "SilentlyContinue"

# Check API
try {
    $r = Invoke-RestMethod -Uri "http://127.0.0.1:18789/status" -TimeoutSec 5
    $apiStatus = "OK"
} catch {
    $apiStatus = "FAIL: $($_.Exception.Message)"
}

# Check process
$proc = Get-Process -Name "node" | Where-Object { $_.CommandLine -like "*openclaw*" } | Select-Object -First 1
if ($proc) {
    $memMB = [math]::Round($proc.WorkingSet64 / 1MB, 2)
    $memStatus = if ($memMB -gt 500) { "WARN" } else { "OK" }
} else {
    $memMB = 0
    $memStatus = "FAIL: not found"
}

# Check config
try {
    $c = Get-Content "$env:USERPROFILE\.openclaw\openclaw.json" -Raw | ConvertFrom-Json | Out-Null
    $cfgStatus = "OK"
} catch {
    $cfgStatus = "FAIL: invalid JSON"
}

$result = @{
    Api = $apiStatus
    Memory = @{ Status = $memStatus; MB = $memMB }
    Config = $cfgStatus
}
$result | ConvertTo-Json -Depth 5
