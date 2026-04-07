#Requires -Version 5.1
# 创建桌面快捷方式

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$batFile = Join-Path $scriptDir "start-gateway.bat"
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktopPath "OpenClaw Gateway.lnk"

if (-not (Test-Path $batFile)) {
    Write-Host "Error: Script not found - $batFile" -ForegroundColor Red
    exit 1
}

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $batFile
$shortcut.WorkingDirectory = $scriptDir
$shortcut.Description = "Start OpenClaw Gateway"
$shortcut.IconLocation = "C:\Windows\System32\shell32.dll,21"
$shortcut.Save()

Write-Host "Shortcut created: $shortcutPath" -ForegroundColor Green
Write-Host ""
Write-Host "To pin to taskbar:" -ForegroundColor Cyan
Write-Host "  1. Double-click to run the shortcut"
Write-Host "  2. Right-click the icon on taskbar"
Write-Host "  3. Select 'Pin to taskbar'"