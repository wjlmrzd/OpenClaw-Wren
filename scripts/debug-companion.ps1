$ErrorActionPreference = 'Continue'
$logDir = 'D:\OpenClaw\.openclaw\logs'
$found = $false
if (Test-Path $logDir) {
    Get-ChildItem $logDir -Filter '*.log' | Sort-Object LastWriteTime -Descending | Select-Object -First 2 | ForEach-Object {
        $f = $_.FullName
        Write-Host "=== $f ==="
        Get-Content $f -Tail 50 | Select-String -Pattern 'companion|companion-check|9f4f1914|SENDING' | Select-Object -Last 10
    }
} else {
    Write-Host "No log dir"
}
# Also check the state
$sf = 'D:\OpenClaw\.openclaw\workspace\memory\companion\state.json'
if (Test-Path $sf) {
    $st = Get-Content $sf -Raw | ConvertFrom-Json
    $lastMsg = $st.lastCompanionMessage
    $lastCheck = $st.lastCheckIn
    Write-Host "lastCompanionMessage=$lastMsg lastCheckIn=$lastCheck"
    $now = (Get-Date).ToUniversalTime().Ticks
    if ($lastMsg -and $lastMsg -gt 0) {
        $elapsed = ($now - $lastMsg) / 36000000
        Write-Host "Elapsed since last msg: $([math]::Round($elapsed,1)) hours"
    } else {
        Write-Host "Never sent a companion message (lastCompanionMessage=0)"
    }
}
