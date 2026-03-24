# 回归测试员工具集
# 用于验证配置和代码变更

function Test-JsonSyntax {
    param([string]$FilePath)
    
    try {
        $content = Get-Content $FilePath -Raw -ErrorAction Stop
        $json = $content | ConvertFrom-Json -ErrorAction Stop
        return @{ Passed = $true; Message = "JSON 语法正确" }
    }
    catch {
        return @{ Passed = $false; Message = "JSON 语法错误：$($_.Exception.Message)" }
    }
}

function Test-ModelNames {
    param([string]$JobsPath = "cron/jobs.json")
    
    $allowedModels = @(
        "dashscope-coding-plan/qwen3.5-plus",
        "dashscope-coding-plan/qwen3-coder-plus",
        "dashscope-coding-plan/qwen3-coder-next",
        "dashscope-coding-plan/glm-5",
        "dashscope-coding-plan/glm-4.7",
        "dashscope-coding-plan/kimi-k2.5",
        "dashscope-coding-plan/minimax-m2.5"
    )
    
    $results = @()
    $jobs = Get-Content $JobsPath -Raw | ConvertFrom-Json
    
    foreach ($job in $jobs.jobs) {
        if ($job.payload.model) {
            $model = $job.payload.model
            if ($allowedModels -notcontains $model) {
                $results += @{
                    JobName = $job.name
                    Model = $model
                    Valid = $false
                    Message = "使用无效模型：$model"
                }
            }
            else {
                $results += @{
                    JobName = $job.name
                    Model = $model
                    Valid = $true
                    Message = "模型有效"
                }
            }
        }
    }
    
    $failed = $results | Where-Object { -not $_.Valid }
    if ($failed.Count -gt 0) {
        return @{
            Passed = $false
            Details = $failed
            Message = "$($failed.Count) 个任务使用无效模型"
        }
    }
    
    return @{ Passed = $true; Message = "所有模型名称有效" }
}

function Test-CronExpressions {
    param([string]$JobsPath = "cron/jobs.json")
    
    $results = @()
    $jobs = Get-Content $JobsPath -Raw | ConvertFrom-Json
    
    foreach ($job in $jobs.jobs) {
        if ($job.schedule.expr) {
            try {
                # 简单验证：检查格式是否正确
                $expr = $job.schedule.expr
                $parts = $expr -split ' '
                if ($parts.Count -lt 5 -or $parts.Count -gt 6) {
                    throw "Cron 表达式必须有 5-6 个部分"
                }
                $results += @{
                    JobName = $job.name
                    Expression = $expr
                    Valid = $true
                }
            }
            catch {
                $results += @{
                    JobName = $job.name
                    Expression = $job.schedule.expr
                    Valid = $false
                    Error = $_.Exception.Message
                }
            }
        }
    }
    
    $failed = $results | Where-Object { -not $_.Valid }
    if ($failed.Count -gt 0) {
        return @{
            Passed = $false
            Details = $failed
            Message = "$($failed.Count) 个任务的 Cron 表达式无效"
        }
    }
    
    return @{ Passed = $true; Message = "所有 Cron 表达式有效" }
}

function Test-GatewayHealth {
    param([string]$GatewayUrl = "http://127.0.0.1:18789")
    
    try {
        $response = Invoke-WebRequest -Uri "$GatewayUrl/status" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            return @{
                Passed = $true
                Message = "Gateway 健康 (响应时间：$($response.ResponseTime)ms)"
                ResponseTime = $response.ResponseTime
            }
        }
        else {
            return @{
                Passed = $false
                Message = "Gateway 返回状态码：$($response.StatusCode)"
            }
        }
    }
    catch {
        return @{
            Passed = $false
            Message = "Gateway 无法访问：$($_.Exception.Message)"
        }
    }
}

function Test-PowerShellSyntax {
    param([string]$ScriptPath)
    
    try {
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $ScriptPath -Raw), [ref]$errors)
        if ($errors.Count -eq 0) {
            return @{ Passed = $true; Message = "PowerShell 语法正确" }
        }
        else {
            return @{ Passed = $false; Message = "PowerShell 语法错误：$($errors[0].Message)" }
        }
    }
    catch {
        return @{ Passed = $false; Message = "PowerShell 语法检查失败：$($_.Exception.Message)" }
    }
}

function Get-FileHashes {
    param([string[]]$Files)
    
    $hashes = @{}
    foreach ($file in $Files) {
        if (Test-Path $file) {
            $hash = Get-FileHash $file -Algorithm SHA256
            $hashes[$file] = $hash.Hash
        }
    }
    return $hashes
}

function Invoke-RegressionTests {
    param(
        [switch]$Full,
        [string]$StatePath = "memory/test-runner-state.json"
    )
    
    Write-Host "=== 回归测试开始 ==="
    $startTime = Get-Date
    $results = @{
        Total = 0
        Passed = 0
        Failed = 0
        Warnings = 0
        Details = @()
    }
    
    # T001: JSON 语法验证
    Write-Host "T001: JSON 语法验证..."
    $test = Test-JsonSyntax -FilePath "cron/jobs.json"
    $results.Total++
    if ($test.Passed) { $results.Passed++ } else { $results.Failed++ }
    $results.Details += @{ Id = "T001"; Name = "JSON 语法验证"; Result = $test }
    
    # T002: 模型名称验证
    Write-Host "T002: 模型名称验证..."
    $test = Test-ModelNames
    $results.Total++
    if ($test.Passed) { $results.Passed++ } else { $results.Failed++ }
    $results.Details += @{ Id = "T002"; Name = "模型名称验证"; Result = $test }
    
    # T003: Cron 表达式验证
    Write-Host "T003: Cron 表达式验证..."
    $test = Test-CronExpressions
    $results.Total++
    if ($test.Passed) { $results.Passed++ } else { $results.Failed++ }
    $results.Details += @{ Id = "T003"; Name = "Cron 表达式验证"; Result = $test }
    
    # T004: Gateway 健康检查
    Write-Host "T004: Gateway 健康检查..."
    $test = Test-GatewayHealth
    $results.Total++
    if ($test.Passed) { $results.Passed++ } else { $results.Failed++ }
    $results.Details += @{ Id = "T004"; Name = "Gateway 健康检查"; Result = $test }
    
    # T005: PowerShell 语法 (仅完整测试)
    if ($Full) {
        Write-Host "T005: PowerShell 语法检查..."
        $scripts = Get-ChildItem "scripts/*.ps1"
        foreach ($script in $scripts) {
            $test = Test-PowerShellSyntax -ScriptPath $script.FullName
            $results.Total++
            if ($test.Passed) { $results.Passed++ } else { $results.Warnings++ }
            $results.Details += @{ Id = "T005"; Name = "PowerShell 语法 - $($script.Name)"; Result = $test }
        }
    }
    
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    
    Write-Host "`n=== 测试结果 ==="
    Write-Host "总计：$($results.Total) | 通过：$($results.Passed) | 失败：$($results.Failed) | 警告：$($results.Warnings)"
    Write-Host "耗时：$([math]::Round($duration, 2)) 秒"
    
    return $results
}

# 导出函数
Export-ModuleMember -Function Test-JsonSyntax, Test-ModelNames, Test-CronExpressions, Test-GatewayHealth, Test-PowerShellSyntax, Get-FileHashes, Invoke-RegressionTests
