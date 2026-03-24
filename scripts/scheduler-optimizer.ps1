# Scheduler Optimizer - 调度优化器
# 分析 Cron 任务执行时间，检测冲突，自动优化调度

param(
    [switch]$Analyze,
    [switch]$Optimize,
    [switch]$Report
)

$workspaceRoot = "D:\OpenClaw\.openclaw\workspace"
$cronJobsPath = "D:\OpenClaw\.openclaw\cron\jobs.json"
$optimizerStatePath = Join-Path $workspaceRoot "memory\scheduler-optimizer-state.json"
$optimizationReportPath = Join-Path $workspaceRoot "memory\scheduler-optimization-report.json"

Write-Host "=== Scheduler Optimizer 调度优化器 ===" -ForegroundColor Cyan
Write-Host "分析时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# ==================== 1. 读取 Cron 任务配置 ====================
Write-Host "[1/5] 读取 Cron 任务配置..." -ForegroundColor Yellow

$jobs = @()
if (Test-Path $cronJobsPath) {
    try {
        $jobsData = Get-Content $cronJobsPath -Raw | ConvertFrom-Json
        $jobs = $jobsData.jobs | Where-Object { $_.enabled -eq $true }
        Write-Host "  读取到 $($jobs.Count) 个启用的任务" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ 无法读取 jobs.json: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  ✗ jobs.json 不存在" -ForegroundColor Red
    exit 1
}

# ==================== 2. 分析任务执行时间分布 ====================
Write-Host "[2/5] 分析任务执行时间分布..." -ForegroundColor Yellow

$hourlyDistribution = @{}
for ($i = 0; $i -lt 24; $i++) {
    $hourlyDistribution[$i] = @{
        count = 0
        tasks = @()
        load = "low"
    }
}

foreach ($job in $jobs) {
    $schedule = $job.schedule
    if ($schedule.kind -eq "cron") {
        $expr = $schedule.expr
        # 解析 cron 表达式的小时部分
        if ($expr -match '^0\s+(\d+|\*|(\d+-\d+)(/\d+)?)\s') {
            $hourPart = $matches[1]
            
            if ($hourPart -eq "*") {
                # 每小时执行
                for ($h = 0; $h -lt 24; $h++) {
                    $hourlyDistribution[$h].count++
                    $hourlyDistribution[$h].tasks += $job.name
                }
            } elseif ($hourPart -match '^(\d+)-(\d+)$') {
                # 小时范围
                $startHour = [int]$matches[1]
                $endHour = [int]$matches[2]
                for ($h = $startHour; $h -le $endHour; $h++) {
                    $hourlyDistribution[$h].count++
                    $hourlyDistribution[$h].tasks += $job.name
                }
            } elseif ($hourPart -match '^\d+$') {
                # 具体小时
                $hour = [int]$hourPart
                $hourlyDistribution[$hour].count++
                $hourlyDistribution[$hour].tasks += $job.name
            }
        }
    }
}

# 计算负载等级
foreach ($hour in $hourlyDistribution.Keys) {
    $count = $hourlyDistribution[$hour].count
    if ($count -ge 4) {
        $hourlyDistribution[$hour].load = "critical"
    } elseif ($count -ge 2) {
        $hourlyDistribution[$hour].load = "high"
    } elseif ($count -eq 1) {
        $hourlyDistribution[$hour].load = "medium"
    }
}

# 输出时间分布
Write-Host "  24 小时任务分布:" -ForegroundColor Gray
$criticalHours = @()
$highLoadHours = @()
for ($h = 0; $h -lt 24; $h++) {
    $dist = $hourlyDistribution[$h]
    if ($dist.count -gt 0) {
        $color = switch ($dist.load) {
            "critical" { "Red"; $criticalHours += $h }
            "high" { "Yellow"; $highLoadHours += $h }
            "medium" { "Cyan" }
            default { "Gray" }
        }
        $timeStr = "{0:D2}:00" -f $h
        Write-Host "    $timeStr - $($dist.count) 个任务 [$($dist.load)]" -ForegroundColor $color
    }
}

# ==================== 3. 检测任务冲突 ====================
Write-Host "[3/5] 检测任务冲突..." -ForegroundColor Yellow

$conflicts = @()
$highLoadTasks = @("备份管理员", "日志清理员", "安全审计员", "每日早报", "网站监控员")

# 检查高负载任务是否在同一时间
foreach ($hour in $criticalHours) {
    $tasksAtHour = $hourlyDistribution[$hour].tasks
    $highLoadAtHour = $tasksAtHour | Where-Object { $_ -in $highLoadTasks }
    
    if ($highLoadAtHour.Count -ge 2) {
        $conflicts += @{
            hour = $hour
            tasks = $highLoadAtHour
            severity = "critical"
            reason = "multiple_high_load_tasks"
        }
        Write-Host "  ⚠ 冲突：${hour}:00 - $($highLoadAtHour -join ', ')" -ForegroundColor Red
    }
}

foreach ($hour in $highLoadHours) {
    $tasksAtHour = $hourlyDistribution[$hour].tasks
    if ($tasksAtHour.Count -ge 3) {
        $conflicts += @{
            hour = $hour
            tasks = $tasksAtHour
            severity = "warning"
            reason = "too_many_tasks"
        }
        Write-Host "  ⚡ 拥挤：${hour}:00 - $($tasksAtHour.Count) 个任务" -ForegroundColor Yellow
    }
}

if ($conflicts.Count -eq 0) {
    Write-Host "  ✓ 未检测到严重冲突" -ForegroundColor Green
} else {
    Write-Host "  发现 $($conflicts.Count) 个冲突" -ForegroundColor Red
}

# ==================== 4. 生成优化建议 ====================
Write-Host "[4/5] 生成优化建议..." -ForegroundColor Yellow

$optimizations = @()

# 优化策略：错开高负载任务
foreach ($conflict in $conflicts) {
    if ($conflict.severity -eq "critical") {
        # 为每个高负载任务建议新的执行时间
        $tasksToMove = $conflict.tasks[1..($conflict.tasks.Count - 1)]  # 保留第一个，移动其他
        
        foreach ($taskName in $tasksToMove) {
            $job = $jobs | Where-Object { $_.name -eq $taskName }
            if ($job) {
                $currentExpr = $job.schedule.expr
                $newHour = ($conflict.hour + 1) % 24  # 移动到下一小时
                
                # 生成新的 cron 表达式
                $parts = $currentExpr -split '\s+'
                if ($parts.Count -ge 2) {
                    $parts[1] = $newHour.ToString()
                    $newExpr = $parts -join ' '
                    
                    $optimizations += @{
                        taskId = $job.id
                        taskName = $taskName
                        currentSchedule = $currentExpr
                        suggestedSchedule = $newExpr
                        reason = "avoid_conflict_with_$($conflict.tasks[0])"
                        priority = "high"
                    }
                    
                    Write-Host "  → 建议：$taskName 从 ${conflict.hour}:00 移至 ${newHour}:00" -ForegroundColor Yellow
                }
            }
        }
    }
}

# 检查 08:00 附近的任务（早报/网站监控）
$eightAmTasks = $hourlyDistribution[8].tasks
if ($eightAmTasks.Count -ge 2) {
    Write-Host "  ℹ 08:00 有 $($eightAmTasks.Count) 个任务，建议错开" -ForegroundColor Yellow
    
    # 将网站监控移到 08:10
    $webMonitorJob = $jobs | Where-Object { $_.name -eq "🌐 网站监控员" }
    if ($webMonitorJob) {
        $currentExpr = $webMonitorJob.schedule.expr
        $newExpr = $currentExpr -replace '^0 8', '10 8'
        
        $optimizations += @{
            taskId = $webMonitorJob.id
            taskName = $webMonitorJob.name
            currentSchedule = $currentExpr
            suggestedSchedule = $newExpr
            reason = "avoid_conflict_with_daily_report"
            priority = "medium"
        }
        
        Write-Host "  → 建议：网站监控员从 08:00 移至 08:10" -ForegroundColor Yellow
    }
}

# ==================== 5. 应用优化（可选） ====================
Write-Host "[5/5] 应用优化..." -ForegroundColor Yellow

$appliedCount = 0

if ($Optimize -and $optimizations.Count -gt 0) {
    Write-Host "  ⚠ 自动优化功能需要确认，当前仅生成建议" -ForegroundColor Yellow
    Write-Host "  要应用优化，请手动更新 jobs.json 或使用 -Report 查看详细建议" -ForegroundColor Gray
} else {
    Write-Host "  ℹ 跳过优化应用 (使用 -Optimize 启用)" -ForegroundColor Gray
}

# ==================== 保存状态和报告 ====================
$optimizerState = [PSCustomObject]@{
    lastAnalysis = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    totalTasks = $jobs.Count
    hourlyDistribution = $hourlyDistribution
    conflicts = $conflicts
    optimizations = $optimizations
    appliedCount = $appliedCount
}

$optimizerState | ConvertTo-Json -Depth 10 | Set-Content -Path $optimizerStatePath

# 生成详细报告
$report = [PSCustomObject]@{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    summary = @{
        totalTasks = $jobs.Count
        criticalHours = $criticalHours.Count
        highLoadHours = $highLoadHours.Count
        conflictsDetected = $conflicts.Count
        optimizationsSuggested = $optimizations.Count
    }
    conflicts = $conflicts
    optimizations = $optimizations
    recommendations = @(
        if ($criticalHours.Count -gt 0) { "避免在 $($criticalHours -join ', ') 点安排高负载任务" }
        if ($conflicts.Count -gt 0) { "优先解决 $($conflicts.Count) 个任务冲突" }
        if ($optimizations.Count -gt 0) { "应用 $($optimizations.Count) 个调度优化建议" }
        "保持每小时任务数 ≤ 2 个以确保稳定性"
    )
}

$report | ConvertTo-Json -Depth 10 | Set-Content -Path $optimizationReportPath

# ==================== 输出报告 ====================
if ($Report) {
    Write-Host ""
    Write-Host "=== 调度优化报告 ===" -ForegroundColor Cyan
    Write-Host "任务总数：$($jobs.Count)" -ForegroundColor Yellow
    Write-Host "冲突检测：$($conflicts.Count)" -ForegroundColor $(if ($conflicts.Count -gt 0) { "Red" } else { "Green" })
    Write-Host "优化建议：$($optimizations.Count)" -ForegroundColor Yellow
    Write-Host ""
    
    if ($optimizations.Count -gt 0) {
        Write-Host "优化建议详情:" -ForegroundColor Cyan
        foreach ($opt in $optimizations) {
            Write-Host "  任务：$($opt.taskName)"
            Write-Host "    当前：$($opt.currentSchedule)"
            Write-Host "    建议：$($opt.suggestedSchedule)"
            Write-Host "    原因：$($opt.reason)"
            Write-Host ""
        }
    }
}

# 返回 JSON 结果
$optimizerState | ConvertTo-Json -Depth 10
