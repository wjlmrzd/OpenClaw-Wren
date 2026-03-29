# 通知网关脚本 - 供 Cron 任务调用
# 使用方式: powershell -File scripts/notification-gateway.ps1 -Action <action> [参数]

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("get-mode", "should-notify", "send", "queue", "get-digest", "clear-pending")]
    [string]$Action,
    
    [string]$Severity = "info",
    [string]$Source = "",
    [string]$Message = "",
    [string]$Target = "8542040756"
)

$statePath = "$PSScriptRoot\..\memory\notification-state.json"

# 确保状态文件存在
if (-not (Test-Path $statePath)) {
    $defaultState = @{
        version = 1
        currentMode = "work_hours"
        silentHours = @{ start = 22; end = 6; timezone = "Asia/Shanghai" }
        silentDigest = @{ enabled = $true; pendingMessages = @(); lastDigestSent = $null }
        severityFilter = @{
            workHours = @("info", "warning", "critical", "emergency")
            evening = @("warning", "critical", "emergency")
            silent = @("critical", "emergency")
        }
        statistics = @{ today = @{ sent = 0; suppressed = 0; queued = 0 } }
        overrides = @{ alwaysNotifySources = @(); emergencyContacts = @("8542040756") }
    }
    $defaultState | ConvertTo-Json -Depth 10 | Out-File $statePath -Encoding UTF8
}

# 加载状态
$state = Get-Content $statePath -Raw | ConvertFrom-Json -AsHashtable

# 获取当前时段模式
function Get-CurrentModeFunc {
    $hour = (Get-Date).Hour
    if ($hour -ge 22 -or $hour -lt 6) { return "silent" }
    elseif ($hour -ge 18 -and $hour -lt 22) { return "evening" }
    else { return "work_hours" }
}

# 更新当前模式（如果需要）
$currentMode = Get-CurrentModeFunc
if ($state.currentMode -ne $currentMode) {
    $state.currentMode = $currentMode
    $state.lastModeChange = [int64]((Get-Date -UFormat %s) * 1000)
    $state | ConvertTo-Json -Depth 10 | Out-File $statePath -Encoding UTF8
}

switch ($Action) {
    "get-mode" {
        Write-Output $state.currentMode
    }
    
    "should-notify" {
        $mode = $state.currentMode
        $allowedSeverities = $state.severityFilter[$mode]
        $shouldNotify = $allowedSeverities -contains $Severity
        
        if ($state.overrides.alwaysNotifySources -contains $Source) {
            $shouldNotify = $true
        }
        
        Write-Output $shouldNotify
    }
    
    "send" {
        Write-Host "[NOTIFY] Severity=$Severity, Message=$Message"
        exit 0
    }
    
    "queue" {
        $pendingMessage = @{
            timestamp = [int64]((Get-Date -UFormat %s) * 1000)
            severity = $Severity
            source = $Source
            message = $Message
        }
        
        $state.silentDigest.pendingMessages += $pendingMessage
        $state.statistics.today.queued++
        $state | ConvertTo-Json -Depth 10 | Out-File $statePath -Encoding UTF8
    }
    
    "get-digest" {
        $pending = $state.silentDigest.pendingMessages
        
        if ($pending.Count -eq 0) {
            $output = @"
🌅 早晨摘要 - $(Get-Date -Format 'yyyy-MM-dd')

✅ 夜间平静
- 系统运行正常
- 无警告/紧急事件
- 所有任务执行成功

祝您有美好的一天！☀️
"@
            Write-Output $output
        }
        else {
            $warnings = @($pending | Where-Object { $_.severity -eq "warning" })
            $critical = @($pending | Where-Object { $_.severity -eq "critical" })
            $emergency = @($pending | Where-Object { $_.severity -eq "emergency" })
            
            $status = "✅ 正常"
            if ($emergency.Count -gt 0) { $status = "🔴 异常" }
            elseif ($critical.Count -gt 0) { $status = "⚠️ 需关注" }
            
            $output = @"
🌅 早晨摘要 - $(Get-Date -Format 'yyyy-MM-dd')

📊 夜间概览:
- 系统状态: $status
- 事件总数: $($pending.Count) 条
- 通知抑制: $($state.statistics.today.suppressed) 条

"@
            
            if ($warnings.Count -gt 0) {
                $output += "⚠️ 夜间警告 ($($warnings.Count) 条):`n"
                foreach ($w in $warnings) {
                    $time = [DateTimeOffset]::FromUnixTimeMilliseconds($w.timestamp).ToLocalTime().ToString("HH:mm")
                    $output += "- $time - $($w.source): $($w.message)`n"
                }
                $output += "`n"
            }
            
            if ($critical.Count -gt 0 -or $emergency.Count -gt 0) {
                $output += "🔴 紧急事件 ($($critical.Count + $emergency.Count) 条):`n"
                foreach ($c in ($critical + $emergency)) {
                    $time = [DateTimeOffset]::FromUnixTimeMilliseconds($c.timestamp).ToLocalTime().ToString("HH:mm")
                    $output += "- $time - $($c.source): $($c.message)`n"
                }
                $output += "`n"
            }
            
            $output += "📋 今日关注:`n"
            if ($emergency.Count -gt 0) {
                $output += "🆘 有紧急事件需要立即处理`n"
            }
            elseif ($critical.Count -gt 0) {
                $output += "⚠️ 有需要关注的问题`n"
            }
            else {
                $output += "✅ 无特殊事项`n"
            }
            
            Write-Output $output
        }
    }
    
    "clear-pending" {
        $count = $state.silentDigest.pendingMessages.Count
        $state.silentDigest.pendingMessages = @()
        $state.silentDigest.lastDigestSent = [int64]((Get-Date -UFormat %s) * 1000)
        $state | ConvertTo-Json -Depth 10 | Out-File $statePath -Encoding UTF8
        
        Write-Host "[CLEARED] $count messages"
    }
}