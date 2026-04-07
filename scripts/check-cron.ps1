# UTF-8 with BOM check
$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Cron Job Files ==="
$jobs = Get-ChildItem "D:\OpenClaw\.openclaw\agents\main\cron" -Recurse -File
Write-Host "Cron job files: $($jobs.Count)"

Write-Host ""
Write-Host "=== Cron State Files ==="
$state = Get-ChildItem "D:\OpenClaw\.openclaw\workspace\memory" -Filter "cron*.json"
foreach ($f in $state) {
    Write-Host "$($f.Name): $(Get-Content $f.FullName -Raw | ConvertFrom-Json | Measure-Object | Select-Object -ExpandProperty Count) jobs"
}

Write-Host ""
Write-Host "=== Recent Gateway Logs (errors/warnings) ==="
$log = Get-Content "D:\OpenClaw\.openclaw\logs\gateway.log" -Tail 100 -ErrorAction SilentlyContinue
$log | Select-String -Pattern "cron|error|Error|WARN" | Select-Object -Last 15 | ForEach-Object { Write-Host $_.Line }
