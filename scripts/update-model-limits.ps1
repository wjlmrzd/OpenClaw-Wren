$json = Get-Content 'D:\OpenClaw\.openclaw\openclaw.json' -Raw -Encoding UTF8 | Out-String
$obj = $json | ConvertFrom-Json

# minimax-coding-plan
$obj.models.providers.'minimax-coding-plan'.models[0].contextWindow = 204800
$obj.models.providers.'minimax-coding-plan'.models[0].maxTokens = 131072

# dashscope models
$ds = $obj.models.providers.'dashscope-coding-plan'.models
foreach ($m in $ds) {
    switch ($m.id) {
        'qwen3.5-plus'    { $m.contextWindow = 262144; $m.maxTokens = 32768 }
        'qwen3-coder-plus' { $m.contextWindow = 998400; $m.maxTokens = 65536 }
        'qwen3-coder-next' { $m.contextWindow = 262144; $m.maxTokens = 65536 }
        'glm-5'           { $m.contextWindow = 200000; $m.maxTokens = 16384 }
        'glm-4.7'         { $m.contextWindow = 200000; $m.maxTokens = 128000 }
        'kimi-k2.5'       { $m.contextWindow = 262144; $m.maxTokens = 32000 }
        'minimax-m2.5'    { $m.contextWindow = 196608; $m.maxTokens = 65536 }
    }
}

$obj | ConvertTo-Json -Depth 20 | Set-Content 'D:\OpenClaw\.openclaw\openclaw.json' -Encoding UTF8
Write-Host 'Done'
