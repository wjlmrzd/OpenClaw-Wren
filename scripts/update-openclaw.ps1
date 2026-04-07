$env:TEMP = "D:\OpenClaw\.npm-temp"
$env:TMP = "D:\OpenClaw\.npm-temp"
npm update -g openclaw-cn --registry https://registry.npmjs.org 2>&1
Write-Host "EXIT_CODE:$LASTEXITCODE"
