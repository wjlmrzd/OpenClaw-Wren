# OpenClaw 自动修复与安全加固脚本 (Windows PowerShell)
# 用途: 定期运行安全审计并自动修复问题

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host "🦞 OpenClaw 自动修复脚本 - $timestamp" -ForegroundColor Cyan

# 1. 运行安全审计
Write-Host "📊 执行安全审计..." -ForegroundColor Yellow
openclaw-cn security audit --deep

# 2. 自动修复安全问题
Write-Host "🔧 执行自动修复..." -ForegroundColor Yellow
openclaw-cn security audit --fix

# 3. 运行doctor检查
Write-Host "🏥 执行健康检查..." -ForegroundColor Yellow
openclaw-cn doctor --fix

# 4. 检查网关状态
Write-Host "🌐 检查网关状态..." -ForegroundColor Yellow
$gatewayStatus = openclaw-cn gateway status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️ 网关未运行，尝试启动..." -ForegroundColor Red
    openclaw-cn gateway start
}

# 5. 备份配置
Write-Host "💾 备份配置..." -ForegroundColor Yellow
$configPath = "$env:OPENCLAW_HOME\.openclaw\openclaw.json"
if (Test-Path $configPath) {
    $backupPath = "$configPath.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Copy-Item $configPath $backupPath
    Write-Host "✅ 配置已备份到: $backupPath" -ForegroundColor Green
}

# 6. 修复Windows权限
Write-Host "🔒 修复文件权限..." -ForegroundColor Yellow
$openclawDir = "$env:OPENCLAW_HOME\.openclaw"
if (Test-Path $openclawDir) {
    icacls $openclawDir /inheritance:r /grant:r "Administrators:(OI)(CI)F" /grant:r "SYSTEM:(OI)(CI)F" 2>$null
}

Write-Host "✅ 自动修复完成" -ForegroundColor Green