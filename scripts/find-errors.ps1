$ErrorActionPreference = 'SilentlyContinue'
$jobs = @()

# Try UTF8
$content = Get-Content "D:\OpenClaw\.openclaw\workspace\memory\cron-list.json" -Raw -Encoding UTF8

# Remove BOM and parse
$json = $content -replace '^\uFEFF', ''
$data = $json | ConvertFrom-Json

Write-Host "=== Issues Found ==="
Write-Host ""

$problemJobs = $data.jobs | Where-Object { $_.state.consecutiveErrors -gt 0 -or $_.state.lastStatus -eq "error" }
foreach ($j in $problemJobs) {
    Write-Host "[ERROR] $($j.name) - consecutiveErrors: $($j.state.consecutiveErrors)"
    Write-Host "  Last Error: $($j.state.lastError)"
    Write-Host "  Timeout: $($j.payload.timeoutSeconds)s, Last Duration: $($j.state.lastDurationMs)ms"
    Write-Host ""
}

Write-Host "=== Jobs with Short Timeouts ==="
$shortTimeout = $data.jobs | Where-Object { $_.payload.timeoutSeconds -lt 180 -and $_.enabled -eq $true }
foreach ($j in $shortTimeout) {
    Write-Host "$($j.name): $($j.payload.timeoutSeconds)s timeout"
}
