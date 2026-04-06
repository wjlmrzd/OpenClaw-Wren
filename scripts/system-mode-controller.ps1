# OpenClaw 运行模式控制器
# 管理系统三种运行状态：正常 / 降载 / 安全

param(
    [string]$Mode = "check",  # check, set, force-safe
    [string]$TargetMode,      # normal, reduced, safe
    [switch]$Force
)

$workspaceRoot = "D:\OpenClaw\.openclaw\workspace"
$openclawRoot = "D:\OpenClaw\.openclaw"
$statePath = Join-Path $workspaceRoot "memory\system-mode-state.json"
$incidentLogPath = Join-Path $workspaceRoot "memory\incident-log.md"
$cronJobsPath = Join-Path $openclawRoot "cron\jobs.json"

# 任务优先级定义
$taskPriorities = @{
    # 高优先级 - 不可停止
    "ccb233d7-0977-4d57-aba7-7564a67041d8" = @{name="🚑 故障自愈员"; priority="high"; category="core"}
    "3a1df011-613d-4528-a274-530cfd84f4fb" = @{name="📡 事件协调员"; priority="high"; category="core"}
    "92af6946-b23b-4534-a6b8-5877cfa36f12" = @{name="🏥 健康监控员"; priority="high"; category="core"}
    
    # 中优先级
    "f920c2a2-6afc-4fc8-84ad-01593d2d22d1" = @{name="⚖️ 资源守护者"; priority="medium"; category="monitoring"}
    "2b564e59-8ed9-4cd8-8345-a9b41e4349bb" = @{name="📝 配置审计师"; priority="medium"; category="monitoring"}
    "53b6edc8-7cc6-4900-ab41-d1abd3e1e15f" = @{name="🛡️ 安全审计员"; priority="medium"; category="monitoring"}
    "e4248abd-0b9b-4540-9bc5-633547462443" = @{name="🧪 回归测试员"; priority="medium"; category="testing"}
    
    # 低优先级 - 可以暂停
    "0e63f087-5446-4033-b826-19dafe65673b" = @{name="📰 每日早报"; priority="low"; category="reporting"}
    "b41843c3-9956-4992-860d-df21cd03a766" = @{name="🌐 网站监控员"; priority="low"; category="reporting"}
    "58540a34-62ab-46a7-a713-cac112e5cd48" = @{name="🏃 运动提醒员"; priority="low"; category="reporting"}
    "2428c991-f51e-47d7-8b6d-0035b8aba1e1" = @{name="📈 每周总结"; priority="low"; category="reporting"}
    "791c995e-4758-469d-ac35-608da1627167" = @{name="📊 运营总监"; priority="low"; category="reporting"}
    "bb0ed170-fa8f-4441-8016-c2119809b436" = @{name="💰 成本分析师"; priority="low"; category="reporting"}
}

# ==================== 系统状态检测 ====================
function Get-SystemMetrics {
    $metrics = @{
        memory = 0
        disk = 0
        cpu = 0
        apiUsage = 0
        consecutiveFailures = 0
        gatewayHealthy = $true
    }
    
    # 内存
    try {
        $os = Get-WmiObject Win32_OperatingSystem
        $metrics.memory = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)
    } catch {}
    
    # 磁盘
    try {
        $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='D:'"
        if ($disk) {
            $metrics.disk = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1)
        }
    } catch {}
    
    # CPU
    try {
        $cpu = Get-WmiObject Win32_Processor
        $avgCpu = $cpu.LoadPercentage | Measure-Object -Average
        $metrics.cpu = [math]::Round($avgCpu.Average, 1)
    } catch {}
    
    # Gateway 状态
    try {
        $response = Invoke-WebRequest -Uri "http://127.0.0.1:18789/status" -TimeoutSec 5 -UseBasicParsing 2>$null
        $metrics.gatewayHealthy = ($response.StatusCode -eq 200)
    } catch {
        $metrics.gatewayHealthy = $false
    }
    
    # 检查连续失败任务（直接读 jobs.json 避免 cron list 超时）
    try {
        $jobsJson = [System.IO.File]::ReadAllText($cronJobsPath, [System.Text.Encoding]::UTF8)
        $jobsData = $jobsJson | ConvertFrom-Json
        $jobs = $jobsData.jobs
        $errorJobs = $jobs | Where-Object { $_.status -eq 'error' }
        $metrics.consecutiveFailures = $errorJobs.Count
    } catch {}
    
    return $metrics
}

# ==================== 模式决策逻辑 ====================
function Get-RecommendedMode {
    param($metrics)
    
    # 安全模式触发条件
    if ($metrics.memory -ge 95 -or $metrics.disk -ge 95 -or -not $metrics.gatewayHealthy -or $metrics.consecutiveFailures -ge 5) {
        return "safe"
    }
    
    # 降载模式触发条件
    if ($metrics.memory -ge 85 -or $metrics.disk -ge 85 -or $metrics.consecutiveFailures -ge 3) {
        return "reduced"
    }
    
    return "normal"
}

# ==================== 状态管理 ====================
function Get-CurrentMode {
    if (Test-Path $statePath) {
        try {
            return (Get-Content $statePath | ConvertFrom-Json).currentMode
        } catch {}
    }
    return "normal"
}

function Set-SystemMode {
    param([string]$Mode)
    
    $state = @{
        currentMode = $Mode
        switchedAt = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        reason = ""
        previousMode = Get-CurrentMode
    }
    
    $state | ConvertTo-Json | Set-Content $statePath -Encoding UTF8
    return $state
}

# ==================== 任务调度调整 ====================
function Adjust-TaskSchedule {
    param([string]$TargetMode)
    
    $actions = @()
    
    try {
        $jobsContent = Get-Content $cronJobsPath -Raw -Encoding UTF8
        $jobs = $jobsContent | ConvertFrom-Json
        
        $modified = $false
        
        foreach ($job in $jobs.jobs) {
            $jobId = $job.id
            if ($taskPriorities.ContainsKey($jobId)) {
                $taskInfo = $taskPriorities[$jobId]
                
                if ($TargetMode -eq "safe") {
                    # 安全模式：只保留高优先级任务
                    if ($taskInfo.priority -ne "high" -and $job.enabled) {
                        $job.enabled = $false
                        $actions += "暂停 $($taskInfo.name) (低优先级)"
                        $modified = $true
                    }
                }
                elseif ($TargetMode -eq "reduced") {
                    # 降载模式：暂停低优先级任务
                    if ($taskInfo.priority -eq "low" -and $job.enabled) {
                        $job.enabled = $false
                        $actions += "暂停 $($taskInfo.name) (低优先级)"
                        $modified = $true
                    }
                }
                elseif ($TargetMode -eq "normal") {
                    # 正常模式：恢复所有任务
                    if (-not $job.enabled) {
                        $job.enabled = $true
                        $actions += "恢复 $($taskInfo.name)"
                        $modified = $true
                    }
                }
            }
        }
        
        if ($modified) {
            # 备份并保存
            $backupPath = Join-Path $workspaceRoot "memory\mode-switch-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
            Copy-Item $cronJobsPath $backupPath
            $jobs | ConvertTo-Json -Depth 10 | Set-Content $cronJobsPath -Encoding UTF8
        }
        
    } catch {
        Write-Host "调整任务失败：$($_.Exception.Message)" -ForegroundColor Red
    }
    
    return $actions
}

# ==================== 主程序 ====================
Write-Host "=== OpenClaw 运行模式控制器 ===" -ForegroundColor Cyan
Write-Host "时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

$currentMode = Get-CurrentMode
Write-Host "当前模式：$currentMode" -ForegroundColor $(if($currentMode -eq "normal"){"Green"}elseif($currentMode -eq "reduced"){"Yellow"}else{"Red"})

if ($Mode -eq "check") {
    # 自动检测并建议
    Write-Host "`n[检测系统状态...]" -ForegroundColor Yellow
    
    $metrics = Get-SystemMetrics
    Write-Host "  内存：$($metrics.memory)%" -ForegroundColor $(if($metrics.memory -gt 90){"Red"}elseif($metrics.memory -gt 80){"Yellow"}else{"Green"})
    Write-Host "  磁盘：$($metrics.disk)%" -ForegroundColor $(if($metrics.disk -gt 90){"Red"}elseif($metrics.disk -gt 80){"Yellow"}else{"Green"})
    Write-Host "  CPU: $($metrics.cpu)%" -ForegroundColor $(if($metrics.cpu -gt 90){"Red"}elseif($metrics.cpu -gt 80){"Yellow"}else{"Green"})
    Write-Host "  Gateway: $(if($metrics.gatewayHealthy){"✅ 正常"}else{"❌ 异常"})" -ForegroundColor $(if($metrics.gatewayHealthy){"Green"}else{"Red"})
    Write-Host "  连续失败任务：$($metrics.consecutiveFailures) 个" -ForegroundColor $(if($metrics.consecutiveFailures -ge 3){"Red"}elseif($metrics.consecutiveFailures -gt 0){"Yellow"}else{"Green"})
    
    $recommended = Get-RecommendedMode -metrics $metrics
    
    if ($recommended -ne $currentMode) {
        Write-Host "`n⚠️ 建议切换模式：$recommended" -ForegroundColor Yellow
        Write-Host "原因：" -ForegroundColor Gray
        
        if ($recommended -eq "safe") {
            if ($metrics.memory -ge 95) { Write-Host "  - 内存超过 95%" -ForegroundColor Red }
            if ($metrics.disk -ge 95) { Write-Host "  - 磁盘超过 95%" -ForegroundColor Red }
            if (-not $metrics.gatewayHealthy) { Write-Host "  - Gateway 异常" -ForegroundColor Red }
            if ($metrics.consecutiveFailures -ge 5) { Write-Host "  - 连续失败任务≥5" -ForegroundColor Red }
        }
        elseif ($recommended -eq "reduced") {
            if ($metrics.memory -ge 85) { Write-Host "  - 内存超过 85%" -ForegroundColor Yellow }
            if ($metrics.disk -ge 85) { Write-Host "  - 磁盘超过 85%" -ForegroundColor Yellow }
            if ($metrics.consecutiveFailures -ge 3) { Write-Host "  - 连续失败任务≥3" -ForegroundColor Yellow }
        }
        
        # 自动切换（除非禁止）
        if (-not $Force) {
            Write-Host "`n[自动切换模式...]" -ForegroundColor Cyan
            Set-SystemMode -Mode $recommended
            $actions = Adjust-TaskSchedule -TargetMode $recommended
            
            if ($actions.Count -gt 0) {
                Write-Host "执行的操作:" -ForegroundColor Yellow
                foreach ($action in $actions) {
                    Write-Host "  - $action" -ForegroundColor Gray
                }
            }
        }
    } else {
        Write-Host "`n✅ 当前模式合适，无需切换" -ForegroundColor Green
    }
    
} elseif ($Mode -eq "set" -and $TargetMode) {
    # 手动设置模式
    Write-Host "`n[手动切换模式：$TargetMode]" -ForegroundColor Cyan
    
    Set-SystemMode -Mode $TargetMode
    $actions = Adjust-TaskSchedule -TargetMode $TargetMode
    
    if ($actions.Count -gt 0) {
        Write-Host "执行的操作:" -ForegroundColor Yellow
        foreach ($action in $actions) {
            Write-Host "  - $action" -ForegroundColor Gray
        }
    }
    
    Write-Host "`n✅ 模式已切换：$TargetMode" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== 完成 ===" -ForegroundColor Cyan
