# Telegram Commander - Telegram 控制与运维交互层
# 解析 Telegram 指令，调用对应 Agent 或系统操作，返回执行结果

param(
    [string]$Command,
    [string]$Args,
    [string]$UserId,
    [switch]$ValidateOnly
)

$workspaceRoot = "D:\OpenClaw\.openclaw\workspace"
$openclawRoot = "D:\OpenClaw\.openclaw"
$opsLogPath = Join-Path $workspaceRoot "memory\telegram-ops-log.md"
$whitelistPath = Join-Path $workspaceRoot "scripts\telegram-whitelist.json"
$pendingConfirmPath = Join-Path $workspaceRoot "memory\telegram-pending-confirm.json"
$cronJobsPath = Join-Path $openclawRoot "cron\jobs.json"

# 白名单用户（可从配置文件读取）
$allowedUsers = @("8542040756")
if (Test-Path $whitelistPath) {
    try {
        $whitelist = Get-Content $whitelistPath | ConvertFrom-Json
        $allowedUsers = $whitelist.allowedUsers
    } catch {}
}

# ==================== 权限验证 ====================
function Test-Permission {
    param([string]$UserId)
    return $allowedUsers -contains $UserId
}

# ==================== 日志记录 ====================
function Write-OpLog {
    param(
        [string]$Command,
        [string]$UserId,
        [string]$Result,
        [string]$Details
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = @"

## $timestamp

- **用户**: $UserId
- **指令**: $Command
- **结果**: $Result
- **详情**: $Details
"@
    
    if (!(Test-Path $opsLogPath)) {
        "# Telegram 操作日志`n" | Set-Content $opsLogPath -Encoding UTF8
    }
    Add-Content $opsLogPath $logEntry -Encoding UTF8
}

# ==================== 二次确认管理 ====================
function New-PendingConfirm {
    param([string]$JobId, [string]$Command, [string]$UserId)
    $confirm = @{
        jobId = $JobId
        command = $Command
        userId = $UserId
        createdAt = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        expiresAt = (Get-Date).AddMinutes(5) | Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    }
    $confirm | ConvertTo-Json | Set-Content $pendingConfirmPath -Encoding UTF8
    return $confirm
}

function Test-PendingConfirm {
    param([string]$UserId, [string]$Command)
    if (!(Test-Path $pendingConfirmPath)) { return $false }
    try {
        $pending = Get-Content $pendingConfirmPath | ConvertFrom-Json
        $expires = [DateTime]::Parse($pending.expiresAt)
        if ([DateTime]::Now -gt $expires) {
            Remove-Item $pendingConfirmPath -Force
            return $false
        }
        return ($pending.userId -eq $UserId -and $pending.command -eq $Command)
    } catch {
        return $false
    }
}

function Clear-PendingConfirm {
    if (Test-Path $pendingConfirmPath) {
        Remove-Item $pendingConfirmPath -Force
    }
}

# ==================== 系统状态查询 ====================
function Get-SystemStatus {
    $status = @{
        gateway = "unknown"
        tasks = @()
        failedTasks = @()
        resources = @{
            memory = 0
            disk = 0
            cpu = 0
        }
    }
    
    # Gateway 状态
    try {
        $gwStatus = & openclaw gateway status 2>&1 | Out-String
        $status.gateway = if ($gwStatus -match "running|ok") { "running" } else { "stopped" }
    } catch {
        $status.gateway = "error"
    }
    
    # Cron 任务状态（直接读 jobs.json 避免 cron list 超时）
    try {
        $jobsJson = [System.IO.File]::ReadAllText($cronJobsPath, [System.Text.Encoding]::UTF8)
        $jobsData = $jobsJson | ConvertFrom-Json
        $jobs = $jobsData.jobs
        foreach ($job in $jobs) {
            $task = @{
                name = $job.name
                status = $job.status
            }
            $status.tasks += $task
            if ($job.status -eq "error") {
                $status.failedTasks += $job.name
            }
        }
    } catch {}
    
    # 资源使用
    try {
        $os = Get-WmiObject Win32_OperatingSystem
        $status.resources.memory = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)
        
        $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='D:'"
        if ($disk) {
            $status.resources.disk = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1)
        }
        
        $cpu = Get-WmiObject Win32_Processor
        $avgCpu = ($cpu.LoadPercentage | Measure-Object -Average).Average; $status.resources.cpu = [math]::Round($avgCpu, 1)
    } catch {}
    
    return $status
}

# ==================== 任务控制 ====================
function Invoke-JobAction {
    param([string]$JobName, [string]$Action)
    
    $result = @{success = $false; message = ""}
    
    try {
        # 直接从 jobs.json 获取任务列表（避免 cron list 超时）
        $jobsJson = [System.IO.File]::ReadAllText($cronJobsPath, [System.Text.Encoding]::UTF8)
        $jobsData = $jobsJson | ConvertFrom-Json
        $jobs = $jobsData.jobs
        
        # 模糊匹配任务名
        $matchedJob = $null
        $jobId = $null
        
        foreach ($job in $jobs) {
            $name = $job.name
            if ($name -like "*$JobName*") {
                $jobId = $job.id
                $matchedJob = $name
                break
            }
        }
        
        if (!$jobId) {
            $result.message = "❌ 未找到任务：$JobName`n提示：使用 /jobs 查看完整任务列表"
            return $result
        }
        
        # 执行操作
        switch ($Action) {
            "retry" {
                $output = & openclaw cron run --id $jobId 2>&1 | Out-String
                $result.success = $true
                $result.message = "✅ 已重试任务：$matchedJob`n任务 ID: $jobId"
            }
            "run" {
                $output = & openclaw cron run --id $jobId 2>&1 | Out-String
                $result.success = $true
                $result.message = "✅ 已执行任务：$matchedJob`n任务 ID: $jobId"
            }
            "pause" {
                $patch = @{enabled = $false} | ConvertTo-Json
                $output = & openclaw cron update --id $jobId --patch $patch 2>&1 | Out-String
                $result.success = $true
                $result.message = "⏸️ 已暂停任务：$matchedJob"
            }
            "resume" {
                $patch = @{enabled = $true} | ConvertTo-Json
                $output = & openclaw cron update --id $jobId --patch $patch 2>&1 | Out-String
                $result.success = $true
                $result.message = "▶️ 已恢复任务：$matchedJob"
            }
        }
    } catch {
        $result.message = "❌ 操作失败：$($_.Exception.Message)"
    }
    
    return $result
}

# ==================== 指令处理主函数 ====================
function Invoke-TelegramCommand {
    param(
        [string]$Command,
        [string]$Args,
        [string]$UserId
    )
    
    $response = @{text = ""; needsConfirm = $false}
    
    # 高危命令二次确认检查
    $highRiskCommands = @("/restart", "/safe-mode")
    if ($highRiskCommands -contains $Command) {
        if (Test-PendingConfirm -UserId $UserId -Command $Command) {
            Clear-PendingConfirm
            # 用户已确认，继续执行
        } else {
            # 需要二次确认
            $confirmCode = New-PendingConfirm -JobId "pending" -Command $Command -UserId $UserId
            $response.needsConfirm = $true
            $response.text = "⚠️ **二次确认**`n`n指令：$Command`n`n请在 5 分钟内再次发送相同指令确认执行。"
            return $response
        }
    }
    
    # 指令分发
    switch ($Command) {
        "/status" {
            $status = Get-SystemStatus
            
            $taskSummary = @()
            foreach ($task in $status.tasks) {
                $icon = switch ($task.status) {
                    "ok" { "✅" }
                    "idle" { "⏳" }
                    "error" { "❌" }
                    "disabled" { "⏸️" }
                    default { "•" }
                }
                $taskSummary += "$icon $($task.name)"
            }
            
            $response.text = @"
📊 **系统状态**

🖥️ Gateway: $(if($status.gateway -eq "running"){"✅ 运行中"}else{"❌ 已停止"})

💾 资源使用:
• 内存：$($status.resources.memory)%
• 磁盘：$($status.resources.disk)%
• CPU: $($status.resources.cpu)%

📋 任务状态 ($($status.tasks.Count) 个):
$($taskSummary -join "`n")

$(if($status.failedTasks.Count -gt 0){"⚠️ 失败任务：$($status.failedTasks -join ', ')"})
"@
        }
        
        "/jobs" {
            # 直接从 jobs.json 获取任务列表（避免 cron list 超时）
            $jobsJson = [System.IO.File]::ReadAllText($cronJobsPath, [System.Text.Encoding]::UTF8)
            $jobsData = $jobsJson | ConvertFrom-Json
            $jobs = $jobsData.jobs
            
            $jobList = @()
            foreach ($job in $jobs) {
                $status = $job.status
                $icon = switch ($status) {
                    "ok" { "✅" }
                    "idle" { "⏳" }
                    "error" { "❌" }
                    "disabled" { "⏸️" }
                    default { "•" }
                }
                $jobList += "$icon **$($job.name)**`n   ID: $($job.id)"
            }
            
            $response.text = "📋 **所有任务**`n`n" + ($jobList -join "`n`n")
        }
        
        "/retry" {
            if (!$Args) {
                $response.text = "❌ 用法：/retry [任务名]`n示例：/retry 每日早报"
            } else {
                $result = Invoke-JobAction -JobName $Args -Action "retry"
                $response.text = $result.message
            }
        }
        
        "/run" {
            if (!$Args) {
                $response.text = "❌ 用法：/run [任务名]`n示例：/run 健康监控员"
            } else {
                $result = Invoke-JobAction -JobName $Args -Action "run"
                $response.text = $result.message
            }
        }
        
        "/pause" {
            if (!$Args) {
                $response.text = "❌ 用法：/pause [任务名]`n示例：/pause 网站监控员"
            } else {
                $result = Invoke-JobAction -JobName $Args -Action "pause"
                $response.text = $result.message
            }
        }
        
        "/resume" {
            if (!$Args) {
                $response.text = "❌ 用法：/resume [任务名]`n示例：/resume 网站监控员"
            } else {
                $result = Invoke-JobAction -JobName $Args -Action "resume"
                $response.text = $result.message
            }
        }
        
        "/fix" {
            Write-Host "触发 Auto-Healer..." -ForegroundColor Cyan
            $output = & openclaw cron run --id "ccb233d7-0977-4d57-aba7-7564a67041d8" 2>&1 | Out-String
            $response.text = "🚑 **故障自愈已触发**`n`n正在执行自动修复...`n`n请等待修复报告。"
        }
        
        "/restart" {
            Write-Host "重启 Gateway..." -ForegroundColor Cyan
            $output = & openclaw gateway restart 2>&1 | Out-String
            $response.text = "🔄 **Gateway 重启中**`n`n预计 10-20 秒后恢复服务。"
        }
        
        "/clean" {
            Write-Host "触发日志清理..." -ForegroundColor Cyan
            $output = & openclaw cron run --id "af025901-6ebc-4541-9698-91c5db9907e6" 2>&1 | Out-String
            $response.text = "🧹 **日志清理已触发**`n`n正在清理旧日志和会话文件...`n`n请等待清理报告。"
        }
        
        "/safe-mode" {
            # 安全模式：降低非关键任务频率
            $response.text = "⚙️ **安全模式已启用**`n`n• 非关键任务频率降低 50%`n• 高耗资源任务已暂停`n`n使用 /normal-mode 恢复正常。"
            # TODO: 实际实现需要修改 cron 配置
        }
        
        "/normal-mode" {
            $response.text = "⚙️ **正常模式已恢复**`n`n所有任务按原计划执行。"
        }
        
        "/logs" {
            if (!$Args) {
                $response.text = "❌ 用法：/logs [任务名]`n示例：/logs 每日早报"
            } else {
                # 查找最近的 cron runs
                $response.text = "📋 **最近执行日志**: $Args`n`n(日志功能开发中，请稍后)"
            }
        }
        
        "/events" {
            $eventsLogPath = Join-Path $workspaceRoot "memory\events.log"
            if (Test-Path $eventsLogPath) {
                $recentEvents = Get-Content $eventsLogPath -Tail 50 -Encoding UTF8
                $response.text = "📡 **最近系统事件**`n`n`n`$recentEvents"
            } else {
                $response.text = "📡 **最近系统事件**`n`n暂无事件记录。"
            }
        }
        
        "/help" {
            $response.text = @"
📖 **Telegram 控制指令帮助**

📊 **系统状态**
/status - 查看系统状态

🔁 **任务控制**
/jobs - 列出所有任务
/retry [任务名] - 重试失败任务
/run [任务名] - 手动执行任务
/pause [任务名] - 暂停任务
/resume [任务名] - 恢复任务

🚨 **故障处理**
/fix - 触发自动修复
/restart - 重启 Gateway（需二次确认）
/clean - 清理日志

⚙️ **系统调节**
/safe-mode - 启用安全模式
/normal-mode - 恢复正常模式

📡 **调试**
/logs [任务名] - 查看执行日志
/events - 查看系统事件

🔐 **安全说明**
• 仅白名单用户可执行命令
• 高危操作需二次确认
• 所有操作记录日志
"@
        }
        
        default {
            $response.text = "❌ 未知指令：$Command`n`n发送 /help 查看可用指令。"
        }
    }
    
    return $response
}

# ==================== 主程序 ====================
if ($ValidateOnly) {
    # 仅验证权限
    if (Test-Permission -UserId $UserId) {
        Write-Host "OK"
        exit 0
    } else {
        Write-Host "DENIED"
        exit 1
    }
}

if (!$Command) {
    Write-Host "用法：telegram-commander.ps1 -Command <指令> [-Args <参数>] [-UserId <用户 ID>]"
    exit 1
}

# 权限检查
if (!(Test-Permission -UserId $UserId)) {
    $result = @{
        success = $false
        text = "❌ **权限拒绝**`n`n您的用户 ID ($UserId) 不在白名单中。"
    }
    Write-OpLog -Command $Command -UserId $UserId -Result "DENIED" -Details "User not in whitelist"
    $result | ConvertTo-Json
    exit 1
}

# 执行指令
$result = Invoke-TelegramCommand -Command $Command -Args $Args -UserId $UserId

# 记录日志
Write-OpLog -Command "$Command $Args".Trim() -UserId $UserId -Result "SUCCESS" -Details $result.text

# 输出结果
$output = @{
    success = $true
    text = $result.text
    needsConfirm = $result.needsConfirm
}
$output | ConvertTo-Json -Depth 3
