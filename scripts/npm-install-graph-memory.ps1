$env:TEMP = "D:\OpenClaw\.npm-temp"
$env:TMP = "D:\OpenClaw\.npm-temp"
$env:npm_config_cache = "D:\OpenClaw\.npm-cache"
Set-Location "D:\OpenClaw\.openclaw\workspace\plugins-graph-memory"
npm install --omit=dev --no-audit --no-fund --ignore-scripts --registry https://registry.npmjs.org 2>&1 | Tee-Object -FilePath "D:\OpenClaw\.npm-cache\_logs\graph-memory-install.log" -Append
Write-Host "EXIT CODE: $LASTEXITCODE"
