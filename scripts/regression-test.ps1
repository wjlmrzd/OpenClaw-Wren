# Regression Test Script for OpenClaw
# Performs core tests to validate configuration integrity

param(
    [string]$OutputDir = "D:\OpenClaw\.openclaw\workspace\memory"
)

# Create timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
$reportFile = Join-Path $OutputDir "test-reports" "regression-test-$timestamp.md"

# Ensure output directory exists
$reportDir = Split-Path $reportFile -Parent
if (!(Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force
}

# Initialize test results
$results = @{}
$failures = @()
$warnings = @()

# Test T001 - JSON Syntax Validation
function Test-JsonSyntax {
    Write-Host "Running T001 - JSON Syntax Validation..."
    
    $jsonFiles = @(
        "D:\OpenClaw\.openclaw\workspace\openclaw.json",
        "D:\OpenClaw\.openclaw\workspace\cron\jobs.json",
        "D:\OpenClaw\.openclaw\workspace\agents\main\openclaw.json"
    )
    
    foreach ($file in $jsonFiles) {
        if (Test-Path $file) {
            try {
                Get-Content $file -Raw | ConvertFrom-Json | Out-Null
                Write-Host "  ✓ $file is valid JSON"
            } catch {
                $error_msg = "Invalid JSON in $file`: $($_.Exception.Message)"
                Write-Host "  ✗ $error_msg"
                $failures += "T001 - JSON Syntax: $error_msg"
                return $false
            }
        } else {
            Write-Host "  ! File not found: $file (skipping)"
        }
    }
    
    return $true
}

# Test T002 - Model Name Validation
function Test-ModelNames {
    Write-Host "Running T002 - Model Name Validation..."
    
    $validModels = @(
        "dashscope-coding-plan/qwen3.5-plus",
        "dashscope-coding-plan/qwen3-coder-plus", 
        "dashscope-coding-plan/qwen3-coder-next",
        "dashscope-coding-plan/glm-5",
        "dashscope-coding-plan/glm-4.7",
        "dashscope-coding-plan/kimi-k2.5",
        "dashscope-coding-plan/minimax-m2.5"
    )
    
    $configFiles = @(
        "D:\OpenClaw\.openclaw\workspace\openclaw.json",
        "D:\OpenClaw\.openclaw\workspace\cron\jobs.json"
    )
    
    foreach ($file in $configFiles) {
        if (Test-Path $file) {
            try {
                $content = Get-Content $file -Raw
                $json = $content | ConvertFrom-Json
                
                # Look for model references in the JSON
                $allMatches = [regex]::Matches($content, '"model"\s*:\s*"([^"]+)"')
                
                foreach ($match in $allMatches) {
                    $model = $match.Groups[1].Value
                    
                    if ($model -notin $validModels) {
                        $error_msg = "Invalid model '$model' found in $file"
                        Write-Host "  ✗ $error_msg"
                        $failures += "T002 - Model Validation: $error_msg"
                        return $false
                    } else {
                        Write-Host "  ✓ Valid model: $model"
                    }
                }
            } catch {
                Write-Host "  ! Could not parse $file for model validation"
            }
        }
    }
    
    return $true
}

# Test T003 - Cron Expression Validation
function Test-CronExpressions {
    Write-Host "Running T003 - Cron Expression Validation..."
    
    $cronFile = "D:\OpenClaw\.openclaw\workspace\cron\jobs.json"
    
    if (Test-Path $cronFile) {
        try {
            $json = Get-Content $cronFile -Raw | ConvertFrom-Json
            
            if ($json -and $json.jobs) {
                foreach ($job in $json.jobs.PSObject.Properties.Value) {
                    if ($job.schedule -and $job.schedule.expr) {
                        $expr = $job.schedule.expr
                        
                        # Basic validation: should have 5-6 parts separated by spaces
                        $parts = $expr.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)
                        
                        if ($parts.Count -lt 5 -or $parts.Count -gt 6) {
                            $error_msg = "Invalid cron expression '$expr' in job $($job.name)"
                            Write-Host "  ✗ $error_msg"
                            $failures += "T003 - Cron Validation: $error_msg"
                            return $false
                        } else {
                            Write-Host "  ✓ Valid cron: $expr"
                        }
                    }
                }
            }
        } catch {
            Write-Host "  ! Could not parse $cronFile for cron validation"
        }
    }
    
    return $true
}

# Test T004 - Gateway Health Check
function Test-GatewayHealth {
    Write-Host "Running T004 - Gateway Health Check..."
    
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-RestMethod -Uri "http://127.0.0.1:18789/openclaw/" -TimeoutSec 10 -ErrorAction Stop
        $stopwatch.Stop()
        
        if ($stopwatch.Elapsed.TotalSeconds -gt 5) {
            $warning_msg = "Gateway response slow: $($stopwatch.Elapsed.TotalSeconds)s (>5s threshold)"
            Write-Host "  ⚠ $warning_msg"
            $warnings += "T004 - Gateway Performance: $warning_msg"
        } else {
            Write-Host "  ✓ Gateway healthy (response: $($stopwatch.Elapsed.TotalSeconds.ToString('F2'))s)"
        }
        
        return $true
    } catch {
        $error_msg = "Gateway health check failed`: $($_.Exception.Message)"
        Write-Host "  ✗ $error_msg"
        $failures += "T004 - Gateway Health: $error_msg"
        return $false
    }
}

# Test T005 - PowerShell Syntax Check
function Test-PowerShellSyntax {
    Write-Host "Running T005 - PowerShell Syntax Check..."
    
    $scriptDir = "D:\OpenClaw\.openclaw\workspace\scripts"
    
    if (Test-Path $scriptDir) {
        $psFiles = Get-ChildItem -Path $scriptDir -Filter "*.ps1" -Recurse
        
        foreach ($file in $psFiles) {
            try {
                $contents = Get-Content $file.FullName -Raw
                $errors = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseInput($contents, [ref]$null, [ref]$errors)
                
                if ($errors.Count -gt 0) {
                    $errorList = $errors | Where-Object { $_.ErrorId -ne 'PSUnusedVariable' }
                    if ($errorList.Count -gt 0) {
                        $warning_msg = "PowerShell syntax issues in $($file.Name): $($errorList[0].Message)"
                        Write-Host "  ⚠ $warning_msg"
                        $warnings += "T005 - PS Syntax: $warning_msg"
                    } else {
                        Write-Host "  ✓ $($file.Name) syntax OK"
                    }
                } else {
                    Write-Host "  ✓ $($file.Name) syntax OK"
                }
            } catch {
                $warning_msg = "Could not parse $($file.Name): $($_.Exception.Message)"
                Write-Host "  ⚠ $warning_msg"
                $warnings += "T005 - PS Syntax: $warning_msg"
            }
        }
    } else {
        Write-Host "  ! Scripts directory not found: $scriptDir"
    }
    
    return $true
}

# Run all tests
Write-Host "`nStarting regression tests..."
Write-Host "Timestamp: $(Get-Date)`n"

$t001_result = Test-JsonSyntax
$t002_result = Test-ModelNames  
$t003_result = Test-CronExpressions
$t004_result = Test-GatewayHealth
$t005_result = Test-PowerShellSyntax

$total_tests = 5
$passed_tests = @($t001_result, $t002_result, $t003_result, $t004_result, $t005_result) | Where-Object { $_ } | Measure-Object | ForEach-Object { $_.Count }

# Generate report
$report_content = @"
# Regression Test Report
**Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Tests Run:** $total_tests
**Tests Passed:** $passed_tests
**Tests Failed:** $($total_tests - $passed_tests)

## Test Results

**T001 - JSON Syntax Validation:** $(if($t001_result){"✅ PASSED"}else{"❌ FAILED"})
**T002 - Model Name Validation:** $(if($t002_result){"✅ PASSED"}else{"❌ FAILED"})  
**T003 - Cron Expression Validation:** $(if($t003_result){"✅ PASSED"}else{"❌ FAILED"})
**T004 - Gateway Health Check:** $(if($t004_result){"✅ PASSED"}else{"❌ FAILED"})
**T005 - PowerShell Syntax Check:** $(if($t005_result){"✅ PASSED"}else{"❌ FAILED"})

"@

if ($failures.Count -gt 0) {
    $report_content += @"
## ❌ Failures

$(($failures | ForEach-Object { "- $_" }) -join "`n")

"@
}

if ($warnings.Count -gt 0) {
    $report_content += @"
## ⚠️ Warnings

$(($warnings | ForEach-Object { "- $_" }) -join "`n")

"@
}

# Write report file
$report_content | Out-File -FilePath $reportFile -Encoding UTF8

# Determine if we need to send notification based on failures and current time
$is_silent_time = $false
$current_hour = (Get-Date).Hour
if ($current_hour -ge 22 -or $current_hour -le 5) {  # 22:00-06:00
    $is_silent_time = $true
}

# Only send notification if there are blocking failures (first 4 tests)
$blocking_failures = $failures | Where-Object { $_ -match "T00[1-4]" }

if ($blocking_failures.Count -gt 0) {
    $blocking_report = @"
🧪 回归测试报告 - $(Get-Date -Format "HH:mm")

❌ 发现失败 ($($blocking_failures.Count)/5 测试)

🔴 阻断性问题:
$(($blocking_failures | ForEach-Object { 
    $num = if ($_ -match "(T\d+)") { $matches[1] } else { "" }
    $desc = switch ($num) {
        "T001" { "JSON 语法验证失败" }
        "T002" { "模型名称验证失败" }
        "T003" { "Cron 表达式验证失败" }
        "T004" { "Gateway 健康检查失败" }
        default { "验证失败" }
    }
    "1. $num - $desc`n   $($_.Replace('T001 - ','').Replace('T002 - ','').Replace('T003 - ','').Replace('T004 - ',''))"
}) -join "`n`n")

🔧 建议动作:
1. 修复上述问题
2. 重新运行测试
3. 检查相关配置文件

📋 详情：$reportFile
"@
    
    # Output the report to stdout for the calling system to handle
    Write-Host "`nALERT_NEEDED:`n$blocking_report"
}

Write-Host "`nRegression testing completed."
Write-Host "Report saved to: $reportFile"