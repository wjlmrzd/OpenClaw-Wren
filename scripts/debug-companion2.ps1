$ErrorActionPreference = 'Continue'
$repo = 'D:\OpenClaw\.openclaw\workspace'
$gatewayUrl = 'http://localhost:18789'
$token = $null
try {
    $cfg = Get-Content "$repo\openclaw.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    $token = $cfg.resolved.gateway.auth.token
} catch {
    Write-Host "[C]No config"
    exit 0
}
if (-not $token) { 
    Write-Host "[C]NoToken"
    exit 0 
}
$hdrs = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }
$h = (Get-Date).Hour
Write-Host "[C]Hour=$h"
if ($h -lt 7 -or $h -ge 23) { Write-Host "[C]Night"; exit 0 }
$rand = Get-Random -Maximum 100
Write-Host "[C]Rand=$rand"
if ($rand -gt 15) { Write-Host "[C]RandSkip"; exit 0 }
$sf = "$repo\memory\companion\state.json"
if (-not (Test-Path $sf)) { 
    Write-Host "[C]NoState"
} else {
    $st = Get-Content $sf -Raw | ConvertFrom-Json
    Write-Host "[C]LastMsg=$($st.lastCompanionMessage)"
}
Write-Host "[C]SHOULD_SEND"
# Determine message for this hour
$msg = $null
if ($h -ge 17 -and $h -lt 18) { 
    $msg = "快下班了，今天的主要任务完成了吗？"
    Write-Host "[C]MsgType=e"
}
if ($msg) { 
    Write-Host "[C]MSG:$msg"
    try {
        $b = @{ channel = 'telegram'; target = '-1003866951105'; message = $msg; threadId = '166' } | ConvertTo-Json -Compress
        Invoke-RestMethod -Uri "$gatewayUrl/api/chat/send" -Method POST -Headers $hdrs -Body $b -TimeoutSec 15
        $st.lm = (Get-Date).ToUniversalTime().Ticks
        $st.c = if ($st.c) { $st.c + 1 } else { 1 }
        $st | ConvertTo-Json | Set-Content $sf -Encoding UTF8
        Write-Host "[C]OK"
    } catch {
        Write-Host "[C]ERR: $($_.Exception.Message)"
    }
} else {
    Write-Host "[C]NoMsg"
}
