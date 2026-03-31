$ErrorActionPreference = "SilentlyContinue"
Write-Host "=== Proxy Port Check ==="
$client = New-Object System.Net.Sockets.TcpClient
$connect = $client.BeginConnect("127.0.0.1", 7897, $null, $null)
$wait = $connect.AsyncWaitHandle.WaitOne(3000, $false)
if ($wait) {
    try { $client.EndConnect($connect); Write-Host "OK - Proxy port 7897 is open" } catch { Write-Host "FAIL - Proxy port 7897 refused" }
} else {
    Write-Host "FAIL - Proxy port 7897 timeout"
}
$client.Close()

Write-Host "`n=== API Tests via Proxy ==="
# Telegram
try {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $r = Invoke-WebRequest -Uri "https://api.telegram.org/bot8329757047:AAEas5LRhvSSGBY6t0zsHzyV8nv_8CZyczA/getMe" -Proxy "http://127.0.0.1:7897" -ProxyUseDefaultCredentials -TimeoutSec 8
    $sw.Stop()
    Write-Host "Telegram: $($r.StatusCode) in $($($sw.ElapsedMilliseconds))ms"
} catch { Write-Host "Telegram: FAIL - $($_.Exception.Message.Substring(0, [Math]::Min(200, $_.Exception.Message.Length)))" }

# Dashscope
try {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $r = Invoke-WebRequest -Uri "https://coding.dashscope.aliyuncs.com/v1/models" -Proxy "http://127.0.0.1:7897" -ProxyUseDefaultCredentials -TimeoutSec 8 -Headers @{"Authorization"="Bearer test"}
    $sw.Stop()
    Write-Host "Dashscope: $($r.StatusCode) in $($($sw.ElapsedMilliseconds))ms"
} catch { Write-Host "Dashscope: FAIL - $($_.Exception.Message.Substring(0, [Math]::Min(200, $_.Exception.Message.Length)))" }

# Minimax
try {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $r = Invoke-WebRequest -Uri "https://api.minimaxi.com/anthropic/v1/models" -Proxy "http://127.0.0.1:7897" -ProxyUseDefaultCredentials -TimeoutSec 8
    $sw.Stop()
    Write-Host "MiniMax: $($r.StatusCode) in $($($sw.ElapsedMilliseconds))ms"
} catch { Write-Host "MiniMax: FAIL - $($_.Exception.Message.Substring(0, [Math]::Min(200, $_.Exception.Message.Length)))" }

Write-Host "`n=== Direct Connectivity ==="
try {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $r = Invoke-WebRequest -Uri "https://www.baidu.com" -TimeoutSec 5
    $sw.Stop()
    Write-Host "Baidu direct: $($r.StatusCode) in $($($sw.ElapsedMilliseconds))ms"
} catch { Write-Host "Baidu direct: FAIL" }
