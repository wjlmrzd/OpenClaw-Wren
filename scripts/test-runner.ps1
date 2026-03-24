# 回归测试员核心测试脚本

param(
    [switch]$DryRun,
    [string]$ReportPath = "memory/test-reports"
)

$ErrorActionPreference = "Continue"
$testResults = @{ Passed = 0; Failed = 0; Warnings = 0; Details = @() }

# 确保报告目录存在
if (!(Test-Path $ReportPath)) { New-Item -ItemType Directory -Force -Path $ReportPath | Out-Null }

# ==================== 核心测试 ====================

function Test-JsonSyntax {
    param([string]$FilePath)
    
    Write-Host "📋 测试：JSON 语法验证 - $FilePath"
    
    if (!(Test-Path $FilePath)) {
        Write-Warning "文件不存在：$FilePath"
        return $null
    }
    
    try {
        $content = Get-Content $FilePath -Raw -Encoding UTF8
        $json = $content | ConvertFrom-Json
        Write-Host "  ✅ 语法正确"
        $testResults.Passed++
        return $json
    }
    catch {
        Write-Error "  ❌ 语法错误：$_"
        $testResults.Failed++
        $testResults.Details += @{
            Test = "JSON 语法验证"
            File = $FilePath
            Status = "Failed"
            Error = $_.Exception.Message
        }
        return $null
    }
}

function Test-ModelValidation {
    param($JobsJson)
    
    Write-Host "📋 测试：模型名称验证"
    
    if (!$JobsJson) {
        Write-Warning "  ⏭️ 跳过（无 jobs.json 数据）"
        return
    }
    
    $allowedModels = @(
        "dashscope-coding-plan/qwen3.5-plus",
        "dashscope-coding-plan/qwen3-coder-plus",
        "dashscope-coding-plan/qwen3-coder-next",
        "dashscope-coding-plan/glm-5",
        "dashscope-coding-plan/glm-4.7",
        "dashscope-coding-plan/kimi-k2.5",
        "dashscope-coding-plan/minimax-m2.5"
    )
    
    $failed = $false
    foreach ($job in $JobsJson.jobs) {
        if ($job.payload -and $job.payload.model) {
            $model = $job.payload.model
            if ($allowedModels -notcontains $model) {
                Write-Error "  ❌ 任务 '$($job.name)' 使用无效模型：$model"
                $testResults.Details += @{
                    Test = "模型名称验证"
                    Job = $job.name
                    Model = $model
                    Status = "Failed"
                    Suggestion = "使用 dashscope-coding-plan/ 前缀的模型"
                }
                $failed = $true
            }
        }
    }
    
    if (!$failed) {
        Write-Host "  ✅ 所有模型名称有效"
        $testResults.Passed++
    } else {
        $testResults.Failed++
    }
}

function Test-CronExpression {
    param($JobsJson)
    
    Write-Host "📋 测试：Cron 表达式验证"
    
    if (!$JobsJson) {
        Write-Warning "  ⏭️ 跳过（无 jobs.json 数据）"
        return
    }
    
    $failed = $false
    foreach ($job in $JobsJson.jobs) {
        if ($job.schedule -and $job.schedule.expr) {
            $expr = $job.schedule.expr
            # 简单验证：5 个字段
            $parts = $expr -split '\s+'
            if ($parts.Count -ne 5) {
                Write-Error "  ❌ 任务 '$($job.name)' cron 表达式格式错误：$expr"
                $testResults.Details += @{
                    Test = "Cron 表达式验证"
                    Job = $job.name
                    Expression = $expr
                    Status = "Failed"
                }
                $failed = $true
            }
        }
    }
    
    if (!$failed) {
        Write-Host "  ✅ 所有 cron 表达式格式正确"
        $testResults.Passed++
    } else {
        $testResults.Failed++
    }
}

function Test-GatewayHealth {
    Write-Host "📋 测试：Gateway 健康检查"
    
    try {
        $response = Invoke-WebRequest -Uri "http://127.0.0.1:18789/status" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "  ✅ Gateway 响应正常 ( $($response.ResponseTime)ms )"
            $testResults.Passed++
        } else {
            Write-Error "  ❌ Gateway 返回状态码：$($response.StatusCode)"
            $testResults.Failed++
            $testResults.Details += @{
                Test = "Gateway 健康检查"
                Status = "Failed"
                StatusCode = $response.StatusCode
            }
        }
    }
    catch {
        Write-Error "  ❌ Gateway 无响应：$_"
        $testResults.Failed++
        $testResults.Details += @{
            Test = "Gateway 健康检查"
            Status = "Failed"
            Error = $_.Exception.Message
        }
    }
}

function Test-PowerShellSyntax {
    param([string]$ScriptPath)
    
    Write-Host "📋 测试：PowerShell 语法 - $ScriptPath"
    
    if (!(Test-Path $ScriptPath)) {
        Write-Warning "  ⏭️ 文件不存在，跳过"
        return
    }
    
    try {
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $ScriptPath -Raw), [ref]$null)
        Write-Host "  ✅ 语法正确"
        $testResults.Passed++
    }
    catch {
        Write-Error "  ❌ 语法错误：$_"
        $testResults.Failed++
        $testResults.Details += @{
            Test = "PowerShell 语法"
            File = $ScriptPath
            Status = "Failed"
        }
    }
}

# ==================== 执行测试 ====================

Write-Host "======================================"
Write-Host "🧪 回归测试员 - 开始执行测试"
Write-Host "======================================"
Write-Host ""

# 1. 测试配置语法
$openclawJson = Test-JsonSyntax "D:\OpenClaw\.openclaw\openclaw.json"
$cronJobsJson = Test-JsonSyntax "D:\OpenClaw\.openclaw\cron\jobs.json"

# 2. 测试模型名称
if ($cronJobsJson) {
    Test-ModelValidation -JobsJson $cronJobsJson
}

# 3. 测试 cron 表达式
if ($cronJobsJson) {
    Test-CronExpression -JobsJson $cronJobsJson
}

# 4. 测试 Gateway 健康
Test-GatewayHealth

# 5. 测试脚本语法
Test-PowerShellSyntax "D:\OpenClaw\.openclaw\workspace\scripts\auto-healer.ps1"
Test-PowerShellSyntax "D:\OpenClaw\.openclaw\workspace\scripts\event-hub-tools.ps1"

# ==================== 生成报告 ====================

Write-Host ""
Write-Host "======================================"
Write-Host "📊 测试摘要"
Write-Host "======================================"
Write-Host "✅ 通过：$($testResults.Passed)"
Write-Host "❌ 失败：$($testResults.Failed)"
Write-Host "⚠️ 警告：$($testResults.Warnings)"
Write-Host ""

if ($testResults.Failed -gt 0) {
    Write-Host "🔴 发现阻断性问题，建议回滚配置！"
    Write-Host ""
    Write-Host "失败详情:"
    $testResults.Details | ForEach-Object {
        Write-Host "  - $($_.Test): $($_.Job) - $($_.Error)"
    }
} else {
    Write-Host "✅ 全部测试通过！"
}

# 返回结果
exit ($testResults.Failed -gt 0 ? 1 : 0)
