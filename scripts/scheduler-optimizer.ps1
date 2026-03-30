# ============================================================
# Scheduler Optimizer - 调度优化器 (自动执行版)
# 分析 Cron 任务执行时间，检测冲突，自动优化调度
# ============================================================
param(
    [switch]$AnalyzeOnly,
    [switch]$AutoExecute,
    [int]$MaxChangesPerRun = 3
)

$ErrorActionPreference = "Continue"
$workspaceRoot = "D:\OpenClaw\.openclaw\workspace"
$cronJobsPath = "D:\OpenClaw\.openclaw\cron\jobs.json"
$statePath = Join-Path $workspaceRoot "memory\scheduler-state.json"

# ============================================================
# 1. 读取任务配置
# ============================================================
Write-Host "=== Scheduler Optimizer ===" -ForegroundColor Cyan
Write-Host "[1/6] 读取任务配置..." -ForegroundColor Yellow

$jobsData = Get-Content $cronJobsPath -Raw | ConvertFrom-Json
$jobs = $jobsData.jobs
Write-Host ("  总任务数: {0}" -f $jobs.Count) -ForegroundColor Gray

# ============================================================
# 2. 解析 cron 表达式
# ============================================================
Write-Host "[2/6] 解析 cron 表达式..." -ForegroundColor Yellow

function Parse-CronExpr($expr) {
    $parts = $expr -split '\s+'
    if ($parts.Count -lt 5) { return @() }

    $minute = $parts[0]
    $hour   = $parts[1]

    $minutes = @()
    if ($minute -eq '*') {
        $minutes = @(0..59)
    } elseif ($minute -match '^\*/(\d+)$') {
        $step = [int]$matches[1]
        for ($i = 0; $i -lt 60; $i += $step) { $minutes += $i }
    } elseif ($minute -match '^(\d+)-(\d+)$') {
        for ($i = [int]$matches[1]; $i -le [int]$matches[2]; $i++) { $minutes += $i }
    } elseif ($minute -match '^(\d+),(\d+)') {
        $minutes = [int[]] ($minute -split ',')
    } else {
        $minutes = @([int]$minute)
    }

    $hours = @()
    if ($hour -eq '*') {
        $hours = @(0..23)
    } elseif ($hour -match '^\*/(\d+)$') {
        $step = [int]$matches[1]
        for ($i = 0; $i -lt 24; $i += $step) { $hours += $i }
    } elseif ($hour -match '^(\d+)-(\d+)$') {
        for ($i = [int]$matches[1]; $i -le [int]$matches[2]; $i++) { $hours += $i }
    } elseif ($hour -match '^\*/(\d+)\s') {
        $step = [int]($hour -replace '^\*/', '')
        for ($i = 0; $i -lt 24; $i += $step) { $hours += $i }
    } elseif ($hour -match '^(\d+),(\d+)') {
        $hours = [int[]] ($hour -split ',')
    } else {
        $hours = @([int]$hour)
    }

    $result = @()
    foreach ($h in $hours) {
        foreach ($m in $minutes) {
            $result += "{0:D2}:{1:D2}" -f $h, $m
        }
    }
    return $result
}

$timeSlots = @{}
foreach ($job in $jobs) {
    if ($job.enabled -ne $true) { continue }
    $expr = $job.schedule.expr
    $times = Parse-CronExpr $expr
    $timeout = $job.payload.timeoutSeconds
    $isHeavy = ($timeout -gt 180)

    foreach ($t in $times) {
        if (-not $timeSlots.ContainsKey($t)) { $timeSlots[$t] = @() }
        $timeSlots[$t] += @{
            id     = $job.id
            name   = $job.name
            expr   = $expr
            timeout = $timeout
            isHeavy = $isHeavy
        }
    }
}

Write-Host ("  解析了 {0} 个时间点" -f $timeSlots.Count) -ForegroundColor Gray

# ============================================================
# 3. 检测碰撞风险
# ============================================================
Write-Host "[3/6] 检测碰撞风险..." -ForegroundColor Yellow

$highRiskSlots = @()
$mediumRiskSlots = @()

foreach ($slot in $timeSlots.Keys) {
    $tasks = $timeSlots[$slot]
    if ($tasks.Count -ge 4) {
        $highRiskSlots += $slot
    } elseif ($tasks.Count -ge 3) {
        $heavyCount = ($tasks | Where-Object { $_.isHeavy }).Count
        if ($heavyCount -ge 2) {
            $highRiskSlots += $slot
        } else {
            $mediumRiskSlots += $slot
        }
    }
}

$highCount = $highRiskSlots.Count
$mediumCount = $mediumRiskSlots.Count

$highColor = if ($highCount -gt 0) { "Red" } else { "Green" }
$medColor  = if ($mediumCount -gt 0) { "Yellow" } else { "Green" }

Write-Host ("  HIGH 风险: {0} 个时间点" -f $highCount) -ForegroundColor $highColor
Write-Host ("  MEDIUM 风险: {0} 个时间点" -f $mediumCount) -ForegroundColor $medColor

# ============================================================
# 4. 生成优化方案
# ============================================================
Write-Host "[4/6] 生成优化方案..." -ForegroundColor Yellow

$plannedChanges = @()

foreach ($slot in ($highRiskSlots + $mediumRiskSlots)) {
    $tasks = $timeSlots[$slot]
    $hour = [int]($slot -split ':')[0]

    $movable = $tasks | Where-Object {
        $tMinute = [int](($_.expr -split '\s+')[0])
        (($tMinute % 5) -eq 0) -and ($tasks.Count -gt 1)
    }

    $sorted = $movable | Sort-Object { -$_.timeout }
    $toMove = $sorted | Select-Object -Skip 1

    $offset = 5
    foreach ($task in $toMove) {
        if ($plannedChanges.Count -ge $MaxChangesPerRun) { break }

        $parts = ($task.expr -split '\s+')
        $oldMinute = [int]$parts[0]
        $newMinute = $oldMinute + $offset
        if ($newMinute -ge 60) {
            $newMinute = $newMinute - 60
            $offset = 1
        }

        $newSlot = "{0:D2}:{1:D2}" -f $hour, $newMinute
        $newCount = if ($timeSlots.ContainsKey($newSlot)) { $timeSlots[$newSlot].Count } else { 0 }

        if ($newCount -le 1) {
            $parts[0] = $newMinute.ToString()
            $newExpr = $parts -join ' '

            $plannedChanges += @{
                taskId  = $task.id
                taskName = $task.name
                oldExpr = $task.expr
                newExpr = $newExpr
                oldSlot = $slot
                newSlot = $newSlot
                reason  = "reduce_collision"
            }
            $msg = "  -> {0}: {1} -> {2}" -f $task.name, $slot, $newSlot
            Write-Host $msg -ForegroundColor Yellow
        }
    }
}

Write-Host ("  计划调整: {0} 个任务" -f $plannedChanges.Count) -ForegroundColor Gray

# ============================================================
# 5. 自动执行优化
# ============================================================
Write-Host "[5/6] 应用优化..." -ForegroundColor Yellow

$appliedChanges = @()
$failedChanges = @()
$cliPath = "openclaw"

foreach ($change in $plannedChanges) {
    if ($AnalyzeOnly) {
        Write-Host ("  [ANALYZE-ONLY] 跳过: {0}" -f $change.taskName) -ForegroundColor Cyan
        continue
    }

    try {
        $result = & $cliPath cron update $change.taskId --schedule $change.newExpr 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host ("  OK {0}: {1} -> {2}" -f $change.taskName, $change.oldSlot, $change.newSlot) -ForegroundColor Green
            $appliedChanges += @{
                taskId   = $change.taskId
                taskName = $change.taskName
                oldExpr  = $change.oldExpr
                newExpr  = $change.newExpr
                oldSlot  = $change.oldSlot
                newSlot  = $change.newSlot
                status   = "success"
                appliedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
            }
        } else {
            Write-Host ("  FAIL {0}: {1}" -f $change.taskName, $result) -ForegroundColor Red
            $failedChanges += $change
        }
    } catch {
        Write-Host ("  ERROR {0}: {1}" -f $change.taskName, $_.Exception.Message) -ForegroundColor Red
        $failedChanges += $change
    }
}

# ============================================================
# 6. 更新状态文件
# ============================================================
Write-Host "[6/6] 更新状态文件..." -ForegroundColor Yellow

$existingState = @{}
if (Test-Path $statePath) {
    try {
        $raw = Get-Content $statePath -Raw
        $existingState = $raw | ConvertFrom-Json
    } catch { $existingState = @{} }
}

$history = @()
if ($existingState.optimizationHistory) {
    $history = @($existingState.optimizationHistory)
}

if ($appliedChanges.Count -gt 0) {
    $detailParts = $appliedChanges | ForEach-Object { "$($_.taskName) $($_.oldSlot)->$($_.newSlot)" }
    $history += @{
        date    = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss+08:00")
        action  = "auto_staggered_scheduling"
        details = ("Adjusted {0} tasks: {1}" -f $appliedChanges.Count, ($detailParts -join ', '))
    }
}

$newState = @{
    lastAnalysisAt    = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss+08:00")
    analysisCycle     = if ($existingState.analysisCycle) { $existingState.analysisCycle + 1 } else { 1 }
    totalTasks        = $jobs.Count
    highRiskSlots     = $highCount
    mediumRiskSlots   = $mediumCount
    plannedChanges    = $plannedChanges.Count
    appliedChanges    = $appliedChanges.Count
    failedChanges     = $failedChanges.Count
    optimizationHistory = $history
    riskLevel         = if ($highCount -gt 0) { "HIGH" } elseif ($mediumCount -gt 0) { "MEDIUM" } else { "LOW" }
    recommendation    = if ($highCount -gt 0) { ("CRITICAL: {0} HIGH-risk slots" -f $highCount) } elseif ($mediumCount -gt 0) { ("WARN: {0} MEDIUM-risk slots" -f $mediumCount) } else { "OK: No collision risks" }
}

$newState | ConvertTo-Json -Depth 10 | Set-Content -Path $statePath -Encoding UTF8

# ============================================================
# 输出摘要
# ============================================================
Write-Host ""
Write-Host "=== 优化完成 ===" -ForegroundColor Cyan
Write-Host ("  HIGH 风险: {0}" -f $highCount) -ForegroundColor $highColor
Write-Host ("  MEDIUM 风险: {0}" -f $mediumCount) -ForegroundColor $medColor
Write-Host ("  计划调整: {0}" -f $plannedChanges.Count) -ForegroundColor Gray
$appColor = if ($appliedChanges.Count -gt 0) { "Green" } else { "Gray" }
Write-Host ("  实际应用: {0}" -f $appliedChanges.Count) -ForegroundColor $appColor
$failColor = if ($failedChanges.Count -gt 0) { "Red" } else { "Gray" }
Write-Host ("  失败: {0}" -f $failedChanges.Count) -ForegroundColor $failColor

# 输出 JSON 供 agent 读取
$result = @{
    highRiskSlots   = $highRiskSlots
    mediumRiskSlots = $mediumRiskSlots
    plannedChanges  = $plannedChanges
    appliedChanges  = $appliedChanges
    failedChanges   = $failedChanges
}
$result | ConvertTo-Json -Depth 5
