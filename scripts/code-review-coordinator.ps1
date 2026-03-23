# Code Review Team Coordinator
# 负责管理 4 人代码评审团队的任务流程

param(
    [string]$Action,
    [string]$TaskId,
    [string]$Request
)

$CodeReviewDir = "D:\OpenClaw\.openclaw\workspace\code-review"
$PluginsDir = "D:\OpenClaw\plugins"

# Cron Job IDs
$DesignerJobId = "a0ea64d4-4118-43e3-9cf3-25dc84909038"
$CheckerJobId = "d10df21e-7512-4751-93c6-0901e51cf632"
$AuditorJobId = "b0006971-6353-49e6-9892-354ec527651d"
$ChiefJobId = "41af46d0-9f18-4f60-b31a-8f5ca02ffe9b"

function New-TaskId {
    return [System.Guid]::NewGuid().ToString().Substring(0, 8)
}

function Start-CodeReview {
    param([string]$Request)
    
    $taskId = New-TaskId
    $taskDir = Join-Path $CodeReviewDir $taskId
    
    Write-Host "🚀 启动代码评审任务：$taskId"
    Write-Host "📁 任务目录：$taskDir"
    
    # 创建任务目录
    New-Item -ItemType Directory -Force -Path $taskDir | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $taskDir "design") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $taskDir "review") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $taskDir "audit") | Out-Null
    
    # 创建任务描述文件
    $taskJson = @{
        taskId = $taskId
        request = $Request
        createdAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        status = "started"
        stage = "design"
    } | ConvertTo-Json -Depth 3
    
    $taskJson | Out-File -FilePath (Join-Path $taskDir "task.json") -Encoding UTF8
    
    # 触发设计师 cron
    Write-Host "⚡ 触发设计师 cron..."
    & openclaw cron run --job-id $DesignerJobId
    
    # 保存任务 ID 供后续使用
    $taskId
}

function Trigger-Checker {
    param([string]$TaskId)
    
    $taskDir = Join-Path $CodeReviewDir $TaskId
    
    if (Test-Path (Join-Path $taskDir "design.done")) {
        Write-Host "✅ 设计完成，触发校核员..."
        & openclaw cron run --job-id $CheckerJobId
    } else {
        Write-Host "⏳ 等待设计完成..."
    }
}

function Trigger-Auditor {
    param([string]$TaskId)
    
    $taskDir = Join-Path $CodeReviewDir $TaskId
    
    if (Test-Path (Join-Path $taskDir "check.done")) {
        Write-Host "✅ 校核完成，触发审核员..."
        & openclaw cron run --job-id $AuditorJobId
    } else {
        Write-Host "⏳ 等待校核完成..."
    }
}

function Trigger-Chief {
    param([string]$TaskId)
    
    $taskDir = Join-Path $CodeReviewDir $TaskId
    
    if (Test-Path (Join-Path $taskDir "audit.done")) {
        Write-Host "✅ 审核完成，触发总工..."
        & openclaw cron run --job-id $ChiefJobId
    } else {
        Write-Host "⏳ 等待审核完成..."
    }
}

function Get-TaskStatus {
    param([string]$TaskId)
    
    $taskDir = Join-Path $CodeReviewDir $TaskId
    $taskFile = Join-Path $taskDir "task.json"
    
    if (Test-Path $taskFile) {
        Get-Content $taskFile -Encoding UTF8 | ConvertFrom-Json
    } else {
        Write-Host "❌ 任务不存在：$TaskId"
    }
}

function List-Tasks {
    Get-ChildItem -Path $CodeReviewDir -Directory | ForEach-Object {
        $taskFile = Join-Path $_.FullName "task.json"
        if (Test-Path $taskFile) {
            $task = Get-Content $taskFile -Encoding UTF8 | ConvertFrom-Json
            [PSCustomObject]@{
                TaskId = $_.Name
                Request = $task.request
                CreatedAt = $task.createdAt
                Status = $task.status
                Stage = $task.stage
            }
        }
    } | Format-Table -AutoSize
}

# 主逻辑
switch ($Action) {
    "start" { Start-CodeReview -Request $Request }
    "trigger-checker" { Trigger-Checker -TaskId $TaskId }
    "trigger-auditor" { Trigger-Auditor -TaskId $TaskId }
    "trigger-chief" { Trigger-Chief -TaskId $TaskId }
    "status" { Get-TaskStatus -TaskId $TaskId }
    "list" { List-Tasks }
    default {
        Write-Host "用法:"
        Write-Host "  .\code-review-coordinator.ps1 start -Request `"生成 XX 插件`""
        Write-Host "  .\code-review-coordinator.ps1 status -TaskId <task-id>"
        Write-Host "  .\code-review-coordinator.ps1 list"
    }
}
