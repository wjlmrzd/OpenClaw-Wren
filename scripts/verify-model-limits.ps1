$obj = (Get-Content 'D:\OpenClaw\.openclaw\openclaw.json' -Raw -Encoding UTF8 | Out-String) | ConvertFrom-Json
Write-Host "=== minimax-2.7 ==="
$obj.models.providers.'minimax-coding-plan'.models[0] | Select-Object id, contextWindow, maxTokens
Write-Host ""
Write-Host "=== dashscope models ==="
$obj.models.providers.'dashscope-coding-plan'.models | Select-Object id, contextWindow, maxTokens
