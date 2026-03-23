# Code Review Team - Quick Launcher
# 当你说"生成 XX 插件"时自动调用此脚本

param(
    [string]$Request
)

$WorkspaceDir = "D:\OpenClaw\.openclaw\workspace"
$TeamName = "review-" + (Get-Date -Format "yyyyMMdd-HHmmss")

Write-Host "🐦 4 人代码评审团队 - ClawTeam 版" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 需求：$Request" -ForegroundColor Yellow
Write-Host "🆔 团队：$TeamName" -ForegroundColor Yellow
Write-Host ""

# 启动 ClawTeam 团队
Write-Host "⚡ 启动团队..." -ForegroundColor Green
Write-Host ""

try {
    # 使用自定义模板 code-review-4person
    Set-Location "$WorkspaceDir\ClawTeam-OpenClaw"
    python -m clawteam launch code-review-4person --team-name $TeamName --goal "$Request"
    
    Write-Host ""
    Write-Host "✅ 团队启动成功！" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 监控命令:" -ForegroundColor Cyan
    Write-Host "  python -m clawteam board show $TeamName     # 看板视图"
    Write-Host "  python -m clawteam board live $TeamName     # 实时监控"
    Write-Host "  python -m clawteam board attach $TeamName   # Tmux 并排视图"
    Write-Host ""
    
} catch {
    Write-Host "❌ 启动失败：$_" -ForegroundColor Red
    exit 1
}
