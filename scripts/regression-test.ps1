# OpenClaw 回归测试
$ErrorActionPreference = 'Continue'
$results = @()

# ===== T001: JSON 语法验证 =====
Write-Host "[T001] JSON 语法验证..."
$t001 = @{ Name = "T001"; Status = "PASS"; Details = "" }
$jsonFiles = @(
    'D:\OpenClaw\.openclaw\openclaw.json',
    'D:\OpenClaw\.openclaw\workspace\cron\jobs.json'
)
foreach ($f in $jsonFiles) {
    if (Test-Path $f) {
        try {
            $null = Get-Content $f -Raw | ConvertFrom-Json
        } catch {
            $t001.Status = "FAIL"
            $t001.Details = "$f - $($_.Exception.Message)"
        }
    }
}
$results += $t001
Write-Host "  $($t001.Status)"

# ===== T002: 模型名称验证 =====
Write-Host "[T002] 模型名称验证..."
$t002 = @{ Name = "T002"; Status = "PASS"; Details = "" }
$validModels = @(
    'dashscope-coding-plan/qwen3.5-plus',
    'dashscope-coding-plan/qwen3-coder-plus',
    'dashscope-coding-plan/qwen3-coder-next',
    'dashscope-coding-plan/glm-5',
    'dashscope-coding-plan/glm-4.7',
    'dashscope-coding-plan/kimi-k2.5',
    'dashscope-coding-plan/minimax-m2.5'
)
$jobsPath = 'D:\OpenClaw\.openclaw\workspace\cron\jobs.json'
if (Test-Path $jobsPath) {
    $jobs = Get-Content $jobsPath -Raw | ConvertFrom-Json
    $errors = @()
    foreach ($job in $jobs) {
        if ($job.payload.model -and $validModels -notcontains $job.payload.model) {
            $errors += "$($job.name): $($job.payload.model)"
        }
    }
    if ($errors.Count -gt 0) {
        $t002.Status = "FAIL"
        $t002.Details = $errors -join "; "
    }
}
$results += $t002
Write-Host "  $($t002.Status)"

# ===== T003: Cron 表达式验证 =====
Write-Host "[T003] Cron 表达式验证..."
$t003 = @{ Name = "T003"; Status = "PASS"; Details = "" }
if (Test-Path $jobsPath) {
    $jobs = Get-Content $jobsPath -Raw | ConvertFrom-Json
    $errors = @()
    foreach ($job in $jobs) {
        if ($job.schedule.kind -eq 'cron') {
            $parts = ($job.schedule.expr -split '\s+').Count
            if ($parts -lt 5 -or $parts -gt 6) {
                $errors += "$($job.name): $($job.schedule.expr)"
            }
        }
    }
    if ($errors.Count -gt 0) {
        $t003.Status = "FAIL"
        $t003.Details = $errors -join "; "
    }
}
$results += $t003
Write-Host "  $($t003.Status)"

# ===== T004: Gateway 健康检查 =====
Write-Host "[T004] Gateway 健康检查..."
$t004 = @{ Name = "T004"; Status = "PASS"; Details = "" }
try {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $resp = Invoke-WebRequest -Uri 'http://127.0.0.1:18789/openclaw/' -TimeoutSec 5 -UseBasicParsing
    $sw.Stop()
    if ($resp.StatusCode -ne 200) {
        $t004.Status = "FAIL"
        $t004.Details = "Status: $($resp.StatusCode)"
    }
} catch {
    $t004.Status = "FAIL"
    $t004.Details = $_.Exception.Message
}
$results += $t004
Write-Host "  $($t004.Status)"

# ===== 输出汇总 =====
Write-Host ""
Write-Host "=== 测试结果汇总 ==="
$results | ForEach-Object {
    Write-Host "$($_.Name): $($_.Status)"
    if ($_.Details) { Write-Host "  $($_.Details)" }
}
$failCount = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
Write-Host ""
Write-Host "失败: $failCount/4"
