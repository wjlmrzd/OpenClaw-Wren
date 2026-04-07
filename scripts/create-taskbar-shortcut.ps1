#Requires -Version 5.1
# 创建桌面快捷方式并准备固定到任务栏

$ErrorActionPreference = "Stop"

# 路径
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$batFile = Join-Path $scriptDir "启动 OpenClaw Gateway.bat"
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktopPath "OpenClaw Gateway.lnk"

# 检查批处理文件
if (-not (Test-Path $batFile)) {
    Write-Host "❌ 找不到启动脚本: $batFile" -ForegroundColor Red
    exit 1
}

# 创建快捷方式
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $batFile
$shortcut.WorkingDirectory = $scriptDir
$shortcut.Description = "启动 OpenClaw Gateway"
$shortcut.IconLocation = "C:\Windows\System32\shell32.dll,21"  # 终端图标
$shortcut.Save()

Write-Host "✅ 已创建桌面快捷方式: $shortcutPath" -ForegroundColor Green
Write-Host ""
Write-Host "📌 固定到任务栏的方法:" -ForegroundColor Cyan
Write-Host "   1. 右键点击桌面上的快捷方式" -ForegroundColor White
Write-Host "   2. 选择「固定到任务栏」" -ForegroundColor White
Write-Host ""
Write-Host "   或者:" -ForegroundColor White
Write-Host "   1. 双击运行快捷方式" -ForegroundColor White
Write-Host "   2. 在任务栏右键点击图标" -ForegroundColor White
Write-Host "   3. 选择「固定到任务栏」" -ForegroundColor White