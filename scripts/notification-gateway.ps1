# 情境感知静默工具
# 用于智能通知管理

function Get-CurrentMode {
    $hour = (Get-Date).Hour
    
    if ($hour -ge 22 -or $hour -lt 6) {
        return "silent"
    }
    elseif ($hour -ge 18 -and $hour -lt 22) {
        return "evening"
    }
    else {
        return "work_hours"
    }
}

function Test-ShouldNotify {
    param(
        [string]$Severity,  # info, warning, critical, emergency
        [string]$Source = ""
    )
    
    $mode = Get-CurrentMode
    $statePath = "memory/notification-state.json"
    
    # 加载配置
    if (Test-Path $statePath) {
        $state = Get-Content $statePath -Raw | ConvertFrom-Json
    }
    else {
        $state = @{
            severityFilter = @{
                workHours = @("info", "warning", "critical", "emergency")
                evening = @("warning", "critical", "emergency")
                silent = @("critical", "emergency")
            }
            overrides = @{
                alwaysNotifySources = @()
            }
        }
    }
    
    # 检查是否在 alwaysNotifySources 中
    if ($state.overrides.alwaysNotifySources -contains $Source) {
        return $true
    }
    
    # 根据模式和严重性判断
    $allowedSeverities = $state.severityFilter.$mode
    
    return $allowedSeverities -contains $severity
}

function Add-ToPendingMessages {
    param(
        [string]$Message,
        [string]$Severity = "warning",
        [string]$Source = ""
    )
    
    $statePath = "memory/notification-state.json"
    $state = Get-Content $statePath -Raw | ConvertFrom-Json
    
    $pendingMessage = @{
        timestamp = [int64]((Get-Date -UFormat %s) + "000")
        severity = $severity
        source = $source
        message = $message
    }
    
    $state.silentDigest.pendingMessages += $pendingMessage
    $state.statistics.today.suppressed++
    
    $state | ConvertTo-Json -Depth 10 | Set-Content $statePath -Encoding UTF8
}

function Send-SmartNotification {
    param(
        [string]$Message,
        [string]$Severity = "info",
        [string]$Source = "",
        [string]$Target = "8542040756"
    )
    
    $shouldNotify = Test-ShouldNotify -Severity $severity -Source $source
    
    if ($shouldNotify) {
        # 发送通知
        Write-Host "发送通知：$Message"
        # 这里调用 message 工具发送
        # sessions_send -target $target -message $message
        return @{ Sent = $true; Reason = "severity_allowed" }
    }
    else {
        # 累积到待发送队列
        Write-Host "抑制通知，累积到早晨摘要：$Message"
        Add-ToPendingMessages -Message $Message -Severity $severity -Source $source
        return @{ Sent = $false; Reason = "silent_period" }
    }
}

function Get-MorningDigest {
    $statePath = "memory/notification-state.json"
    $state = Get-Content $statePath -Raw | ConvertFrom-Json
    
    $pending = $state.silentDigest.pendingMessages
    
    if ($pending.Count -eq 0) {
        return @{
            HasEvents = $false
            Content = "✅ 夜间平静`n- 系统运行正常`n- 无警告/紧急事件`n- 所有任务执行成功`n`n祝您有美好的一天！☀️"
        }
    }
    
    # 分类事件
    $warnings = $pending | Where-Object { $_.severity -eq "warning" }
    $critical = $pending | Where-Object { $_.severity -eq "critical" }
    $emergency = $pending | Where-Object { $_.severity -eq "emergency" }
    
    # 生成摘要
    $digest = "🌅 早晨摘要 - $(Get-Date -Format 'yyyy-MM-dd')`n`n"
    $digest += "📊 夜间概览:`n"
    $digest += "- 系统状态：$(if ($emergency.Count -gt 0) { '🔴 异常' } elseif ($critical.Count -gt 0) { '⚠️ 需关注' } else { '✅ 正常' })`n"
    $digest += "- 事件总数：$($pending.Count) 条`n"
    $digest += "- 通知抑制：$($state.statistics.today.suppressed) 条`n`n"
    
    if ($warnings.Count -gt 0) {
        $digest += "⚠️ 夜间警告 ($($warnings.Count) 条):`n"
        foreach ($w in $warnings) {
            $time = Get-Date -Date ([DateTimeOffset]::FromUnixTimeMilliseconds($w.timestamp).DateTime) -Format "HH:mm"
            $digest += "- $time - $($w.source): $($w.message)`n"
        }
        $digest += "`n"
    }
    
    if ($critical.Count -gt 0 -or $emergency.Count -gt 0) {
        $digest += "🔴 紧急事件 ($($critical.Count + $emergency.Count) 条):`n"
        foreach ($c in ($critical + $emergency)) {
            $time = Get-Date -Date ([DateTimeOffset]::FromUnixTimeMilliseconds($c.timestamp).DateTime) -Format "HH:mm"
            $digest += "- $time - $($c.source): $($c.message)`n"
        }
        $digest += "`n"
    }
    
    $digest += "📋 今日关注:`n"
    if ($emergency.Count -gt 0) {
        $digest += "🆘 有紧急事件需要立即处理`n"
    }
    elseif ($critical.Count -gt 0) {
        $digest += "⚠️ 有需要关注的问题`n"
    }
    else {
        $digest += "✅ 无特殊事项`n"
    }
    
    return @{
        HasEvents = $true
        Content = $digest
        PendingCount = $pending.Count
    }
}

function Clear-PendingMessages {
    $statePath = "memory/notification-state.json"
    $state = Get-Content $statePath -Raw | ConvertFrom-Json
    
    $state.silentDigest.pendingMessages = @()
    $state.silentDigest.lastDigestSent = [int64]((Get-Date -UFormat %s) + "000")
    $state.statistics.today.suppressed = 0
    $state.statistics.today.queued = 0
    
    $state | ConvertTo-Json -Depth 10 | Set-Content $statePath -Encoding UTF8
}

# 导出函数
Export-ModuleMember -Function Get-CurrentMode, Test-ShouldNotify, Add-ToPendingMessages, Send-SmartNotification, Get-MorningDigest, Clear-PendingMessages
