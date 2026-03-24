# Auto-Healer v2 - 增强版故障自愈脚本
# 具备自动重试、模型切换、Gateway 重启能力
# 新增：自愈风暴防护（10 分钟内最多 3 次修复）

param([switch]$DryRun, [switch]$Verbose)

$workspaceRoot = "D:\OpenClaw\.openclaw\workspace"
$openclawRoot = "D:\OpenClaw\.openclaw"
$healingReportPath = Join-Path $workspaceRoot "memory\auto-healer-report.json"
$incidentLogPath = Join-Path $workspaceRoot "memory\incident-log.md"
$cronJobsPath = Join-Path $openclawRoot "cron\jobs.json"
$stabilityStatePath = Join-Path $workspaceRoot "memory\stability-state.json"

# ==================== 自愈风暴防护检查 ====================
function Test-HealerStormProtection {
    $statePath = $stabilityStatePath
    
    if (Test-Path $statePath) {
        $state = Get-Content $statePath | ConvertFrom-Json
        $protection = $state.healerStormProtection
        
        if ($protection) {
            $now = Get-Date
            $windowMinutes = if ($protection.windowMinutes) { $protection.windowMinutes } else { 10 }
            $maxRepairs = if ($protection.maxRepairsPerWindow) { $protection.maxRepairsPerWindow } else { 3 }
            
            # 检查时间窗口是否过期
            if ($protection.windowStart) {
                $windowStart = [datetime]$protection.windowStart
                $windowEnd = $windowStart.AddMinutes($windowMinutes)
                
                if ($now -gt $windowEnd) {
                    # 窗口过期，重置
                    Write-Host "🔄 自愈风暴保护窗口重置" -ForegroundColor Gray
                    $protection.windowStart = $now.ToString("yyyy-MM-ddTHH:mm:ssZ")
                    $protection.repairCount = 0
                    $state.healerStormProtection = $protection
                    $state | ConvertTo-Json -Depth 10 | Set-Content $statePath -Encoding UTF8
                    return @{allowed=$true; count=0; max=$maxRepairs}
                }
                
                # 检查是否超过限制
                if ($protection.repairCount -ge $maxRepairs) {
                    Write-Host "🛑 自愈风暴保护触发！10 分钟内已达 $maxRepairs 次修复上限" -ForegroundColor Red
                    return @{allowed=$false; count=$protection.repairCount; max=$maxRepairs; reason="storm_protection"}
                }
                
                return @{allowed=$true; count=$protection.repairCount; max=$maxRepairs}
            }
        }
    }
    
    # 初始化保护状态
    return @{allowed=$true; count=0; max=3}
}

function Record-RepairAction {
    $statePath = $stabilityStatePath
    
    if (Test-Path $statePath) {
        $state = Get-Content $statePath | ConvertFrom-Json
        
        if ($state.healerStormProtection) {
            $state.healerStormProtection.repairCount++
            $count = $state.healerStormProtection.repairCount
            $max = $state.healerStormProtection.maxRepairsPerWindow
            
            Write-Host "📝 记录修复动作 ( $($count)/$($max) )" -ForegroundColor Gray
            
            $state | ConvertTo-Json -Depth 10 | Set-Content $statePath -Encoding UTF8
        }
    }
}

# 检查自愈风暴保护
$stormProtection = Test-HealerStormProtection
if (-not $stormProtection.allowed) {
    Write-Host "⏸️ 暂停自愈操作，等待风暴保护窗口重置" -ForegroundColor Yellow
    Write-Host "  原因：$($stormProtection.reason)" -ForegroundColor Gray
    exit 0
}
Write-Host "🛡️ 自愈风暴保护：$($stormProtection.count)/$($stormProtection.max) 修复次数" -ForegroundColor Green
Write-Host ""

# 模型故障转移链
$modelFailover = @(
    "dashscope-coding-plan/qwen3.5-plus",
    "dashscope-coding-plan/glm-5",
    "dashscope-coding-plan/qwen3-coder-plus",
    "dashscope-coding-plan/kimi-k2.5"
)

Write-Host "=== Auto-Healer v2 故障自愈 ===" -ForegroundColor Cyan
Write-Host "时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

$systemStatus = @{healthy=$true; issuesFound=0; issuesFixed=0; alertsGenerated=0}
$fixActions = @()
$alerts = @()
$retryQueue = @()

# ==================== 1. 检查失败任务 ====================
Write-Host "[1/6] 检查 Cron 任务状态..." -ForegroundColor Yellow

$failedTasks = @()
$errorTasks = @()

try {
    $cronOutput = & openclaw cron list 2>&1 | Out-String
    $lines = $cronOutput -split "`n" | Where-Object { $_.Trim() -ne "" }
    
    foreach ($line in $lines) {
        if ($line -match '([a-f0-9-]{36})\s+(.+?)\s+(error|disabled)') {
            $jobId = $matches[1]
            $jobName = $matches[2].Trim()
            $status = $matches[3]
            
            $task = @{
                id = $jobId
                name = $jobName
                status = $status
                consecutiveErrors = 0
            }
            
            # 尝试提取错误次数
            if ($line -match 'consecutiveErrors:\s*(\d+)') {
                $task.consecutiveErrors = [int]$matches[1]
            }
            
            $failedTasks += $task
            
            if ($task.consecutiveErrors -ge 3) {
                $errorTasks += $task
            }
        }
    }
    
    if ($failedTasks.Count -gt 0) {
        Write-Host "  发现 $($failedTasks.Count) 个失败任务" -ForegroundColor Red
        foreach ($task in $failedTasks) {
            Write-Host "    - $($task.name) (错误：$($task.consecutiveErrors) 次)" -ForegroundColor Gray
        }
        $systemStatus.issuesFound += $failedTasks.Count
    } else {
        Write-Host "  ✅ 所有任务正常" -ForegroundColor Green
    }
} catch {
    Write-Host "  ❌ 检查失败：$($_.Exception.Message)" -ForegroundColor Red
}

# ==================== 2. 自动重试失败任务 ====================
Write-Host "`n[2/6] 执行自动重试..." -ForegroundColor Yellow

foreach ($task in $failedTasks) {
    if ($task.consecutiveErrors -lt 3) {
        # 延迟策略：根据错误次数决定延迟时间
        $delaySeconds = switch ($task.consecutiveErrors) {
            0 { 0 }
            1 { 60 }    # 1 分钟后
            2 { 300 }   # 5 分钟后
            default { 900 }  # 15 分钟后
        }
        
        if ($delaySeconds -gt 0) {
            Write-Host "  ⏳ $($task.name): 延迟 $delaySeconds 秒后重试" -ForegroundColor Yellow
            $retryQueue += @{
                taskId = $task.id
                taskName = $task.name
                delaySeconds = $delaySeconds
                retryAt = (Get-Date).AddSeconds($delaySeconds)
            }
        } else {
            Write-Host "  🔄 $($task.name): 立即重试" -ForegroundColor Cyan
            if (-not $DryRun) {
                try {
                    $output = & openclaw cron run --id $task.id 2>&1 | Out-String
                    $fixActions += @{
                        action = "retry_task"
                        taskId = $task.id
                        taskName = $task.name
                        result = "executed"
                    }
                    $systemStatus.issuesFixed++
                    Record-RepairAction  # 记录修复次数（风暴防护）
                } catch {
                    Write-Host "    重试失败：$($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
    }
}

# ==================== 3. 处理连续失败任务 ====================
Write-Host "`n[3/6] 处理连续失败任务..." -ForegroundColor Yellow

foreach ($task in $errorTasks) {
    Write-Host "  ⚠️ $($task.name): 连续失败 $($task.consecutiveErrors) 次" -ForegroundColor Red
    
    # 记录到 incident log
    $incidentEntry = @"

## $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

- **任务**: $($task.name)
- **ID**: $($task.id)
- **连续失败**: $($task.consecutiveErrors) 次
- **状态**: 需要人工干预
- **建议**: 检查任务配置、模型可用性、超时设置

"@
    
    if (!(Test-Path $incidentLogPath)) {
        "# 事件日志 - Incident Log`n" | Set-Content $incidentLogPath -Encoding UTF8
    }
    Add-Content $incidentLogPath $incidentEntry -Encoding UTF8
    
    # 生成告警
    $alerts += @{
        level = "warning"
        task = $task.name
        message = "连续失败 $($task.consecutiveErrors) 次，需要人工干预"
        incidentLogged = $true
    }
    $systemStatus.alertsGenerated++
    
    # 尝试模型切换（如果是模型错误）
    try {
        $jobsContent = Get-Content $cronJobsPath -Raw -Encoding UTF8
        $jobs = $jobsContent | ConvertFrom-Json
        
        $targetJob = $jobs.jobs | Where-Object { $_.id -eq $task.id }
        if ($targetJob -and $targetJob.payload.model) {
            $currentModel = $targetJob.payload.model
            $currentModelIndex = $modelFailover.IndexOf($currentModel)
            
            if ($currentModelIndex -ge 0 -and $currentModelIndex -lt ($modelFailover.Count - 1)) {
                $newModel = $modelFailover[$currentModelIndex + 1]
                Write-Host "    尝试模型切换：$currentModel → $newModel" -ForegroundColor Yellow
                
                if (-not $DryRun) {
                    $targetJob.payload.model = $newModel
                    $jobs | ConvertTo-Json -Depth 10 | Set-Content $cronJobsPath -Encoding UTF8
                    
                    $fixActions += @{
                        action = "switch_model"
                        taskId = $task.id
                        taskName = $task.name
                        fromModel = $currentModel
                        toModel = $newModel
                    }
                    $systemStatus.issuesFixed++
                    Record-RepairAction  # 记录修复次数（风暴防护）
                }
            }
        }
    } catch {
        Write-Host "    模型切换失败：$($_.Exception.Message)" -ForegroundColor Red
    }
}

# ==================== 4. 检查 Gateway 状态 ====================
Write-Host "`n[4/6] 检查 Gateway 状态..." -ForegroundColor Yellow

$gatewayHealthy = $true
try {
    $response = Invoke-WebRequest -Uri "http://127.0.0.1:18789/status" -TimeoutSec 5 -UseBasicParsing 2>$null
    if ($response.StatusCode -eq 200) {
        Write-Host "  ✅ Gateway 运行正常" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Gateway 响应异常" -ForegroundColor Red
        $gatewayHealthy = $false
    }
} catch {
    Write-Host "  ❌ Gateway 无法访问" -ForegroundColor Red
    $gatewayHealthy = $false
}

if (-not $gatewayHealthy) {
    Write-Host "  🔄 尝试重启 Gateway..." -ForegroundColor Yellow
    
    if (-not $DryRun) {
        try {
            & openclaw gateway restart 2>&1 | Out-Null
            Start-Sleep -Seconds 10
            
            # 验证重启成功
            $retryCount = 0
            while ($retryCount -lt 3) {
                try {
                    $response = Invoke-WebRequest -Uri "http://127.0.0.1:18789/status" -TimeoutSec 5 -UseBasicParsing 2>$null
                    if ($response.StatusCode -eq 200) {
                        Write-Host "  ✅ Gateway 重启成功" -ForegroundColor Green
                        $fixActions += @{action="restart_gateway"; result="success"}
                        $systemStatus.issuesFixed++
                        Record-RepairAction  # 记录修复次数（风暴防护）
                        break
                    }
                } catch {}
                $retryCount++
                Start-Sleep -Seconds 5
            }
            
            if ($retryCount -eq 3) {
                Write-Host "  ❌ Gateway 重启失败，需要人工干预" -ForegroundColor Red
                $alerts += @{
                    level = "critical"
                    message = "Gateway 重启失败，需要立即处理"
                }
                $systemStatus.alertsGenerated++
            }
        } catch {
            Write-Host "  ❌ 重启失败：$($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# ==================== 5. 检查资源状态 ====================
Write-Host "`n[5/6] 检查系统资源..." -ForegroundColor Yellow

# 内存
try {
    $os = Get-WmiObject Win32_OperatingSystem
    $memPercent = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)
    Write-Host "  内存：${memPercent}%" -ForegroundColor $(if($memPercent -gt 90){"Red"}elseif($memPercent -gt 80){"Yellow"}else{"Green"})
    
    if ($memPercent -gt 95) {
        Write-Host "  ⚠️ 内存严重不足，建议重启 Gateway" -ForegroundColor Red
        $fixActions += @{action="suggest_gateway_restart"; reason="memory_critical"; value=$memPercent}
    } elseif ($memPercent -gt 90) {
        Write-Host "  ⚠️ 内存紧张，准备清理" -ForegroundColor Yellow
    }
} catch {}

# 磁盘
try {
    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='D:'"
    if ($disk) {
        $diskPercent = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1)
        Write-Host "  磁盘：${diskPercent}%" -ForegroundColor $(if($diskPercent -gt 90){"Red"}elseif($diskPercent -gt 85){"Yellow"}else{"Green"})
        
        if ($diskPercent -gt 95) {
            Write-Host "  ⚠️ 磁盘严重不足，触发紧急清理" -ForegroundColor Red
            $fixActions += @{action="emergency_cleanup"; reason="disk_critical"; value=$diskPercent}
        } elseif ($diskPercent -gt 85) {
            Write-Host "  ⚠️ 磁盘紧张，建议清理日志" -ForegroundColor Yellow
            $fixActions += @{action="suggest_log_cleanup"; reason="disk_warning"; value=$diskPercent}
        }
    }
} catch {}

# ==================== 6. 执行修复行动 ====================
Write-Host "`n[6/6] 执行修复行动..." -ForegroundColor Yellow

if ($fixActions.Count -eq 0) {
    Write-Host "  ✅ 无需修复行动" -ForegroundColor Green
} else {
    foreach ($action in $fixActions) {
        if ($DryRun) {
            Write-Host "  [DRY] $($action.action)" -ForegroundColor Cyan
        } else {
            Write-Host "  -> $($action.action)" -ForegroundColor Yellow
            
            # 执行特定修复行动
            if ($action.action -eq "emergency_cleanup") {
                # 触发日志清理
                try {
                    & openclaw cron run --id "af025901-6ebc-4541-9698-91c5db9907e6" 2>&1 | Out-Null
                    Write-Host "     已触发日志清理任务" -ForegroundColor Green
                } catch {}
            }
        }
    }
}

# ==================== 保存报告 ====================
$report = [PSCustomObject]@{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    systemStatus = $systemStatus
    fixActions = $fixActions
    alerts = $alerts
    retryQueue = $retryQueue | ForEach-Object {
        @{
            taskId = $_.taskId
            taskName = $_.taskName
            retryAt = $_.retryAt.ToString("yyyy-MM-ddTHH:mm:ssZ")
        }
    }
}

$report | ConvertTo-Json -Depth 5 | Set-Content $healingReportPath -Encoding UTF8

# ==================== 输出摘要 ====================
Write-Host ""
Write-Host "=== 修复摘要 ===" -ForegroundColor Cyan
Write-Host "发现问题：$($systemStatus.issuesFound)" -ForegroundColor $(if($systemStatus.issuesFound -gt 0){"Red"}else{"Green"})
Write-Host "已修复：$($systemStatus.issuesFixed)" -ForegroundColor $(if($systemStatus.issuesFixed -gt 0){"Green"}else{"Gray"})
Write-Host "生成告警：$($systemStatus.alertsGenerated)" -ForegroundColor $(if($systemStatus.alertsGenerated -gt 0){"Yellow"}else{"Green"})
Write-Host "等待重试：$($retryQueue.Count)" -ForegroundColor Cyan
Write-Host "报告：$healingReportPath" -ForegroundColor Gray

if ($alerts.Count -gt 0) {
    Write-Host ""
    Write-Host "⚠️ 告警列表:" -ForegroundColor Yellow
    foreach ($alert in $alerts) {
        Write-Host "  [$($alert.level)] $($alert.message)" -ForegroundColor $(if($alert.level -eq "critical"){"Red"}else{"Yellow"})
    }
}

$report | ConvertTo-Json -Depth 5
