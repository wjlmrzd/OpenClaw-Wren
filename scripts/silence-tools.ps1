# 情境感知静默工具集
# 用于智能管理通知时机

function Get-TimePeriod {
    $hour = (Get-Date).Hour
    
    if ($hour -ge 6 -and $hour -lt 9) { return "morning" }
    elseif ($hour -ge 9 -and $hour -lt 12) { return "work_morning" }
    elseif ($hour -ge 12 -and $hour -lt 14) { return "lunch" }
    elseif ($hour -ge 14 -and $hour -lt 18) { return "work_afternoon" }
    elseif ($hour -ge 18 -and $hour -lt 22) { return "evening" }
    else { return "night" }
}

function Test-IsQuietHours {
    param(
        [string]$StartTime = "22:00",
        [string]$EndTime = "06:00"
    )
    
    $now = Get-Date
    $currentHour = $now.Hour
    $currentMinute = $now.Minute
    $currentTime = $currentHour * 60 + $currentMinute
    
    $startParts = $StartTime -split ':'
    $startMinutes = [int]$startParts[0] * 60 + [int]$startParts[1]
    
    $endParts = $EndTime -split ':'
    $endMinutes = [int]$endParts[0] * 60 + [int]$endParts[1]
    
    # 跨夜情况 (如 22:00 - 06:00)
    if ($startMinutes -gt $endMinutes) {
        return ($currentTime -ge $startMinutes -or $currentTime -lt $endMinutes)
    }
    else {
        return ($currentTime -ge $startMinutes -and $currentTime -lt $endMinutes)
    }
}

function Test-IsWeekend {
    $dayOfWeek = (Get-Date).DayOfWeek
    return ($dayOfWeek -eq [DayOfWeek]::Saturday -or $dayOfWeek -eq [DayOfWeek]::Sunday)
}

function Get-NotificationPriority {
    param([string]$Message)
    
    $emergencyKeywords = @("紧急", "故障", "宕机", "危机", "critical", "emergency", "down", "crash")
    $warningKeywords = @("警告", "失败", "超时", "warning", "failed", "timeout")
    $noticeKeywords = @("注意", "提醒", "notice", "alert")
    
    if ($emergencyKeywords | Where-Object { $Message -like "*$_*" }) {
        return "emergency"
    }
    elseif ($warningKeywords | Where-Object { $Message -like "*$_*" }) {
        return "warning"
    }
    elseif ($noticeKeywords | Where-Object { $Message -like "*$_*" }) {
        return "notice"
    }
    else {
        return "info"
    }
}

function Should-Notify {
    param(
        [string]$Priority = "info",
        [string]$StatePath = "memory/silence-state.json"
    )
    
    # 读取状态文件
    $state = if (Test-Path $StatePath) {
        Get-Content $StatePath -Raw | ConvertFrom-Json
    } else {
        return $true # 默认发送
    }
    
    # 紧急级别始终发送
    if ($priority -eq "emergency" -or $priority -eq "critical") {
        return $true
    }
    
    # 检查静默时段
    $quietHours = $state.silenceConfig.quietHours
    $isQuiet = Test-IsQuietHours -StartTime $quietHours.start -EndTime $quietHours.end
    
    if ($isQuiet) {
        # 静默时段：仅允许特定 Agent 和紧急通知
        return $false
    }
    
    # 检查是否在会议中
    if ($state.currentScene.inMeeting) {
        if ($priority -eq "info" -or $priority -eq "notice") {
            return $false
        }
    }
    
    # 检查是否是专注时间
    if ($state.currentScene.isFocusTime) {
        return $false # 专注时间完全静默
    }
    
    # 周末降低频率
    if (Test-IsWeekend) {
        if ($priority -eq "info") {
            # 周末信息类通知 50% 概率发送
            return (Get-Random -Minimum 0 -Maximum 2) -eq 1
        }
    }
    
    return $true
}

function Add-AccumulatedEvent {
    param(
        [string]$EventType,
        [string]$Message,
        [string]$StatePath = "memory/silence-state.json"
    )
    
    $state = Get-Content $StatePath -Raw | ConvertFrom-Json
    
    $event = @{
        timestamp = [int64]((Get-Date -UFormat %s) + "000")
        type = $eventType
        message = $message
        priority = (Get-NotificationPriority -Message $message)
    }
    
    $state.accumulatedEvents += $event
    $state.statistics.silencedToday++
    
    $state | ConvertTo-Json -Depth 10 | Set-Content $StatePath -Encoding UTF8
    
    Write-Host "事件已累积：$eventType - $message"
}

function Flush-AccumulatedEvents {
    param(
        [string]$StatePath = "memory/silence-state.json",
        [string]$TelegramUserId = "8542040756"
    )
    
    $state = Get-Content $StatePath -Raw | ConvertFrom-Json
    $events = $state.accumulatedEvents
    
    if ($events.Count -eq 0) {
        Write-Host "无累积事件"
        return
    }
    
    # 按优先级分组
    $grouped = $events | Group-Object -Property priority
    
    $summary = "🔕 静默时段摘要`n`n"
    $summary += "📊 累积事件：$($events.Count) 个`n"
    
    foreach ($group in $grouped) {
        $emoji = switch ($group.Name) {
            "info" { "🟢" }
            "notice" { "🟡" }
            "warning" { "⚠️" }
            "emergency" { "🔴" }
            default { "📝" }
        }
        $summary += "- $emoji $($group.Name): $($group.Count) 个`n"
    }
    
    Write-Host $summary
    
    # 这里可以调用 message 工具发送 Telegram
    # 实际使用时需要通过 sessions_send 或 message 工具
    
    # 清空累积事件
    $state.accumulatedEvents = @()
    $state.statistics.lastSilentPeriod.end = [int64]((Get-Date -UFormat %s) + "000")
    $state | ConvertTo-Json -Depth 10 | Set-Content $StatePath -Encoding UTF8
    
    Write-Host "已发送累积事件摘要"
}

function Update-SilenceState {
    param([string]$StatePath = "memory/silence-state.json")
    
    $state = if (Test-Path $StatePath) {
        Get-Content $StatePath -Raw | ConvertFrom-Json
    } else {
        @{
            currentTimeContext = @{}
            currentScene = @{}
            silenceConfig = @{ quietHours = @{ start = "22:00"; end = "06:00" } }
            accumulatedEvents = @()
            statistics = @{ silencedToday = 0 }
        }
    }
    
    # 更新时间上下文
    $period = Get-TimePeriod
    $state.currentTimeContext.period = $period
    $state.currentTimeContext.isWeekend = Test-IsWeekend
    $state.currentTimeContext.nextPeriodChange = (Get-Date).AddHours(1).ToString("yyyy-MM-ddTHH:00:00+08:00")
    
    # 检查是否静默时段结束，需要发送累积事件
    $quietHours = $state.silenceConfig.quietHours
    $wasQuiet = Test-IsQuietHours -StartTime $quietHours.start -EndTime $quietHours.end
    
    # 如果刚从静默时段出来且有累积事件，发送摘要
    if (-not $wasQuiet -and $state.accumulatedEvents.Count -gt 0) {
        Flush-AccumulatedEvents -StatePath $StatePath
    }
    
    $state.lastUpdate = [int64]((Get-Date -UFormat %s) + "000")
    $state | ConvertTo-Json -Depth 10 | Set-Content $StatePath -Encoding UTF8
    
    return $state
}

# 导出函数
Export-ModuleMember -Function Get-TimePeriod, Test-IsQuietHours, Test-IsWeekend, Get-NotificationPriority, Should-Notify, Add-AccumulatedEvent, Flush-AccumulatedEvents, Update-SilenceState
