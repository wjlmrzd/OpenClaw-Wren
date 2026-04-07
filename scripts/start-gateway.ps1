#Requires -Version 5.1
# OpenClaw Gateway Quick Launcher

$ErrorActionPreference = "Continue"
$Host.UI.RawUI.WindowTitle = "OpenClaw Gateway"

Clear-Host
Write-Host ""
Write-Host "  OpenClaw Gateway Launcher" -ForegroundColor Cyan
Write-Host "  ================================" -ForegroundColor Cyan
Write-Host ""

# Check Gateway status
Write-Host "  [Checking Gateway status...]" -ForegroundColor Yellow

$statusOutput = openclaw gateway status 2>&1
$statusString = $statusOutput | Out-String

if ($statusString -match "Listening|running|正常") {
    Write-Host "  [OK] Gateway is running" -ForegroundColor Green
    Write-Host ""
    Write-Host $statusString -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Press any key to close..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}

# Start Gateway
Write-Host "  [Starting Gateway...]" -ForegroundColor Yellow

openclaw gateway start 2>&1 | Out-Null
Start-Sleep -Seconds 2

# Verify
$statusOutput = openclaw gateway status 2>&1
$statusString = $statusOutput | Out-String

if ($statusString -match "Listening|正常") {
    Write-Host "  [OK] Gateway started successfully" -ForegroundColor Green
    Write-Host ""
    Write-Host $statusString -ForegroundColor Gray
} else {
    Write-Host "  [WARN] Check status manually" -ForegroundColor Yellow
    Write-Host $statusString -ForegroundColor Gray
}

Write-Host ""
Write-Host "  Press any key to close..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")