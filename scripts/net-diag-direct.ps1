$ErrorActionPreference = "SilentlyContinue"
Write-Host "=== Direct API Tests (no proxy) ==="

# Dashscope direct
try {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $r = Invoke-WebRequest -Uri "https://coding.dashscope.aliyuncs.com/v1/models" -TimeoutSec 8 -Headers @{"Authorization"="Bearer test"}
    $sw.Stop()
    Write-Host "Dashscope DIRECT: $($r.StatusCode) in $($sw.ElapsedMilliseconds)ms"
} catch { Write-Host "Dashscope DIRECT: FAIL - $($_.Exception.Message.Substring(0, [Math]::Min(200, $_.Exception.Message.Length)))" }

# MiniMax direct
try {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $r = Invoke-WebRequest -Uri "https://api.minimaxi.com/anthropic/v1/models" -TimeoutSec 8
    $sw.Stop()
    Write-Host "MiniMax DIRECT: $($r.StatusCode) in $($sw.ElapsedMilliseconds)ms"
} catch { Write-Host "MiniMax DIRECT: FAIL - $($_.Exception.Message.Substring(0, [Math]::Min(200, $_.Exception.Message.Length)))" }

# Telegram direct (no proxy)
try {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $r = Invoke-WebRequest -Uri "https://api.telegram.org/bot8329757047:AAEas5LRhvSSGBY6t0zsHzyV8nv_8CZyczA/getMe" -TimeoutSec 8
    $sw.Stop()
    Write-Host "Telegram DIRECT: $($r.StatusCode) in $($sw.ElapsedMilliseconds)ms"
} catch { Write-Host "Telegram DIRECT: FAIL - $($_.Exception.Message.Substring(0, [Math]::Min(200, $_.Exception.Message.Length)))" }

Write-Host "`n=== System Proxy Status ==="
$proxy = [System.Net.WebRequest]::GetSystemWebProxy()
$uri = New-Object System.Uri("https://coding.dashscope.aliyuncs.com")
$proxyUri = $proxy.GetProxy($uri)
Write-Host "System proxy for Dashscope: $proxyUri"