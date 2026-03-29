# Code Review Team Launcher
# 当你说"生成 XX 插件"时，这个脚本会启动 ClawTeam 4 人评审团队

param(
    [string]$Request,
    [string]$TeamName
)

$WorkspaceDir = "D:\OpenClaw\.openclaw\workspace"
$CodeReviewDir = "D:\OpenClaw\.openclaw\workspace\code-review"
$PluginsDir = "D:\OpenClaw\plugins"

# 生成随机团队名称（如果未提供）
if (-not $TeamName) {
    $TeamName = "review-" + [System.Guid]::NewGuid().ToString().Substring(0, 6)
}

Write-Host "🚀 启动 4 人代码评审团队" -ForegroundColor Green
Write-Host "📋 团队名称：$TeamName"
Write-Host "💬 需求：$Request"
Write-Host ""

# 确保目录存在
if (-not (Test-Path $CodeReviewDir)) {
    New-Item -ItemType Directory -Force -Path $CodeReviewDir | Out-Null
}

# 创建任务记录文件
$taskId = [System.Guid]::NewGuid().ToString().Substring(0, 8)
$taskDir = Join-Path $CodeReviewDir $taskId
New-Item -ItemType Directory -Force -Path $taskDir | Out-Null

$taskInfo = @{
    taskId = $taskId
    teamName = $TeamName
    request = $Request
    startedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    status = "starting"
    stage = "design"
} | ConvertTo-Json -Depth 3

$taskInfo | Out-File -FilePath (Join-Path $taskDir "task.json") -Encoding UTF8

Write-Host "📁 任务目录：$taskDir"
Write-Host "🆔 任务 ID: $taskId"
Write-Host ""

# 启动 ClawTeam 团队
# 使用自定义模板 code-review-4person
Write-Host "⚡ 正在启动 ClawTeam 团队..." -ForegroundColor Cyan

# 构建启动命令
$launchCmd = "cd $WorkspaceDir\ClawTeam-OpenClaw && python -m clawteam launch code-review-4person --team-name $TeamName --goal `"$Request`""

Write-Host "运行命令：$launchCmd"
Write-Host ""

# 执行启动命令
try {
    Invoke-Expression $launchCmd
    Write-Host ""
    Write-Host "✅ 团队启动成功！" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 监控方式:" -ForegroundColor Yellow
    Write-Host "  1. 看板视图：python -m clawteam board show $TeamName"
    Write-Host "  2. 实时视图：python -m clawteam board live $TeamName"
    Write-Host "  3. Tmux 视图：python -m clawteam board attach $TeamName"
    Write-Host "  4. Web 面板：python -m clawteam board serve --port 8080"
    Write-Host ""
    Write-Host "🔍 查看任务状态:" -ForegroundColor Yellow
    Write-Host "  .\code-review-launcher.ps1 status -TaskId $taskId"
} catch {
    Write-Host "❌ 启动失败：$_" -ForegroundColor Red
    $taskInfo.status = "failed"
    $taskInfo | ConvertTo-Json | Out-File -FilePath (Join-Path $taskDir "task.json") -Encoding UTF8
    exit 1
}

# 更新任务状态
$taskInfo.status = "running"
$taskInfo | ConvertTo-Json | Out-File -FilePath (Join-Path $taskDir "task.json") -Encoding UTF8

Write-Host ""
Write-Host "🎯 工作流程:" -ForegroundColor Cyan
Write-Host "  1️⃣  设计师 (qwen3-coder-plus) → 代码架构设计和初版实现"
Write-Host "  2️⃣  校核员 (qwen3.5-plus)     → 代码质量检查和风格审查"
Write-Host "  3️⃣  审核员 (minimax-m2.5)    → 安全性和最佳实践审查"
Write-Host "  4️⃣  总工 (glm-5)            → 最终审批和合并决策"
Write-Host ""
