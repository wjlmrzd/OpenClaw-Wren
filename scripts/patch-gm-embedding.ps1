$file = "D:\OpenClaw\.openclaw\openclaw.json"
$json = Get-Content $file -Raw

if ($json -match '"embedding"') {
    Write-Host "embedding already exists, skipping"
    exit 0
}

# Build the embedding JSON string manually - $$ = literal $ in -replace replacement
$embedJson = '"embedding":{"apiKey":"${DASHSCOPE_API_KEY}","baseURL":"https://dashscope.aliyuncs.com/v1/embeddings","model":"text-embedding-v2","dimensions":512}'

# Find "dedupThreshold": 0.85 followed by closing brace, add embedding after it
$result = $json -replace '("dedupThreshold":\s*0\.85[\s\S]*?})', ('$1,' + $embedJson + '}')

if ($result -eq $json) {
    Write-Host "Pattern not matched"
    exit 1
}

$result | Set-Content $file -NoNewline -Encoding UTF8
Write-Host "Done - embedding config added"
