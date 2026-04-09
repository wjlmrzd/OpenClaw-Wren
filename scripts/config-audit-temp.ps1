$ErrorActionPreference = "SilentlyContinue"
Write-Host "=== CONFIG AUDIT ==="

# openclaw.json
$cfgPath = "D:\OpenClaw\.openclaw\config\openclaw.json"
if (Test-Path $cfgPath) {
    $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
    Write-Host "lastTouchedAt: $($cfg.lastTouchedAt)"
    Write-Host "version: $($cfg.version)"
    Write-Host "logLevel: $($cfg.logLevel)"
} else {
    Write-Host "openclaw.json NOT FOUND at $cfgPath"
}

# cron jobs
Write-Host ""
Write-Host "=== CRON JOBS ==="
$cronDir = "D:\OpenClaw\.openclaw\config\cron"
if (Test-Path $cronDir) {
    Get-ChildItem $cronDir | Format-Table LastWriteTime, Length, Name -AutoSize
} else {
    Write-Host "cron dir NOT FOUND"
}

# jobs.json
$jobsPath = "D:\OpenClaw\.openclaw\config\cron\jobs.json"
if (Test-Path $jobsPath) {
    $j = Get-Content $jobsPath -Raw | ConvertFrom-Json
    Write-Host "Total jobs: $($j.jobs.Count)"
    $enabled = ($j.jobs | Where-Object { $_.enabled -ne $false }).Count
    Write-Host "Enabled jobs: $enabled"
    $last3 = $j.jobs[-1..-3]
    foreach ($job in $last3) {
        Write-Host "  - $($job.id): $($job.name) (enabled=$($job.enabled))"
    }
}

# credentials
Write-Host ""
Write-Host "=== CREDENTIALS ==="
$credDir = "D:\OpenClaw\.openclaw\credentials"
if (Test-Path $credDir) {
    Get-Acl $credDir\* | Format-Table Path,Owner -AutoSize
}

# git status
Write-Host ""
Write-Host "=== GIT STATUS ==="
Set-Location "D:\OpenClaw\.openclaw"
git status --porcelain 2>&1
