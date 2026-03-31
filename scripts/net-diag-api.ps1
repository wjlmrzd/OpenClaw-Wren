$ErrorActionPreference = "SilentlyContinue"
Write-Host "=== Testing correct API endpoints ==="

# Dashscope - OpenAI compatible, try /v1/chat/completions with dummy body
try {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $body = '{"model":"qwen-turbo","messages":[{"role":"user","content":"hi"}],"max_tokens":1}'
    $headers = @{"Authorization"="Bearer invalid-key"}
    $r = Invoke-WebRequest -Uri "https://coding.dashscope.aliyuncs.com/v1/chat/completions" -Method POST -Body $body -ContentType "application/json" -TimeoutSec 10 -Headers $headers
    $sw.Stop()
    Write-Host "Dashscope chat: $($r.StatusCode) in $($sw.ElapsedMilliseconds)ms"
} catch { 
    $msg = $_.Exception.Message
    if ($msg.Length -gt 150) { $msg = $msg.Substring(0, 150) }
    Write-Host "Dashscope chat: $msg"
}

# MiniMax Anthropic - try /v1/messages
try {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $body = '{"model":"claude-3-haiku-20240307","max_tokens":1,"messages":[{"role":"user","content":"hi"}]}'
    $headers = @{"x-api-key"="invalid-key"; "anthropic-version"="2023-06-01"}
    $r = Invoke-WebRequest -Uri "https://api.minimaxi.com/anthropic/v1/messages" -Method POST -Body $body -ContentType "application/json" -TimeoutSec 10 -Headers $headers
    $sw.Stop()
    Write-Host "MiniMax messages: $($r.StatusCode) in $($sw.ElapsedMilliseconds)ms"
} catch { 
    $msg = $_.Exception.Message
    if ($msg.Length -gt 150) { $msg = $msg.Substring(0, 150) }
    Write-Host "MiniMax messages: $msg"
}

# Just ping the base URLs
Write-Host "`n=== Base URL connectivity ==="
try {
    $r = Invoke-WebRequest -Uri "https://coding.dashscope.aliyuncs.com" -TimeoutSec 5
    Write-Host "Dashscope base: $($r.StatusCode)"
} catch { Write-Host "Dashscope base: FAIL" }

try {
    $r = Invoke-WebRequest -Uri "https://api.minimaxi.com" -TimeoutSec 5
    Write-Host "MiniMax base: $($r.StatusCode)"
} catch { Write-Host "MiniMax base: FAIL" }