# 通知协调员 - 情境感知静默实现

param(
    [string]$Action = "check",  # check, send, queue, flush
    [string]$Severity = "info", # info, warning, critical, emergency
    [string]$Message,
    [string]$Source,
    [string]$StatePath = "memory/quiet-mode-state.json"
)

# 确保目录存在
$stateDir = Split-Path $StatePath -Parent
if (!(Test-Path $stateDir)) { New-Item -ItemType Directory -Force -Path $stateDir | Out-Null }

# 加载状态
function Get-QuietState {
    param([string]$Path)
    if (Test-Path $Path) {
        return Get-Content $Path -Raw | ConvertFrom-Json
    } else {
        return @{
            currentMode = "normal"
            quietSchedule = @{ start = "22:00"; end = "06:00" }
            pendingNotifications = @()
            userState = @{ status = "unknown"; lastActive = $null }
            statistics = @{
                today = @{ sent = 0; delayed = 0; suppressed = 0 }
                thisWeek = @{ sent = 0; delayed = 0; suppressed = 0 }
            }
        }
    }
}

function Save-QuietState {
    param([object]$State, [string]$Path)
    $State | ConvertTo-Json -Depth 10 | Set-Content $Path -Encoding UTF8
}

# 检查是否在静默时段
function Test-QuietHours {
    $now = Get-Date
    $startHour = [int]($state.quietSchedule.start -split ':')[0]
    $endHour = [int]($state.quietSchedule.end -split ':')[0]
    
    $currentHour = $now.Hour
    
    # 跨天情况（如 22:00-06:00）
    if ($startHour -gt $endHour) {
        return ($currentHour -ge $startHour -or $currentHour -lt $endHour)
    } else {
        return ($currentHour -ge $startHour -and $currentHour -lt $endHour)
    }
}

# 判断事件严重性级别
function Get-SeverityLevel {
    param([string]$Severity)
    switch ($Severity.ToLower()) {
        "info" { return 1 }
        "warning" { return 2 }
        "critical" { return 3 }
        "emergency" { return 4 }
        default { return 1 }
    }
}

# 决策是否发送通知
function Test-ShouldNotify {
    param(
        [int]$SeverityLevel,
        [bool]$InQuietHours,
        [string]$UserStatus
    )
    
    # 紧急/危机事件：总是通知
    if ($SeverityLevel -ge 4) {
        return $true
    }
    
    # 静默时段
    if ($InQuietHours) {
        # 严重警告在静默时段延迟
        if ($SeverityLevel -ge 3) {
            return $true  # 紧急事件突破静默
        } else {
            return $false  # 其他事件进入队列
        }
    }
    
    # 非静默时段：根据用户状态
    switch ($UserStatus) {
        "active" { return $true }
        "away" { return $SeverityLevel -ge 2 }  # 离开时仅警告以上
        "busy" { return $SeverityLevel -ge 3 }  # 忙碌时仅紧急
        default { return $true }
    }
}

# 主逻辑
$state = Get-QuietState -Path $StatePath
$inQuietHours = Test-QuietHours
$severityLevel = Get-SeverityLevel -Severity $Severity

if ($Action -eq "check") {
    # 检查当前状态
    Write-Host "当前模式：$($state.currentMode)"
    Write-Host "静默时段：$($state.quietSchedule.start) - $($state.quietSchedule.end)"
    Write-Host "是否在静默时段：$inQuietHours"
    Write-Host "用户状态：$($state.userState.status)"
    Write-Host "待发送通知：$($state.pendingNotifications.Count) 条"
    Write-Host ""
    Write-Host "今日统计：发送 $($state.statistics.today.sent), 延迟 $($state.statistics.today.delayed), 静默 $($state.statistics.today.suppressed)"
}
elseif ($Action -eq "send") {
    # 发送通知决策
    $shouldNotify = Test-ShouldNotify -SeverityLevel $severityLevel -InQuietHours $inQuietHours -UserStatus $state.userState.status
    
    if ($shouldNotify) {
        Write-Host "SEND"
        # 更新统计
        $state.statistics.today.sent++
        $state.statistics.thisWeek.sent++
    } else {
        Write-Host "QUEUE"
        # 加入队列
        $state.pendingNotifications += @{
            timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
            severity = $Severity
            source = $Source
            message = $Message
        }
        $state.statistics.today.delayed++
        $state.statistics.thisWeek.delayed++
    }
    
    Save-QuietState -State $state -Path $StatePath
}
elseif ($Action -eq "flush") {
    # 发送累积队列
    if ($state.pendingNotifications.Count -gt 0) {
        Write-Host "FLUSH $($state.pendingNotifications.Count) notifications"
        # 这里应该调用 Telegram API 发送摘要
        # 为简化，仅输出
        $state.pendingNotifications | ForEach-Object {
            Write-Host "  - [$($_.severity)] $($_.source): $($_.message)"
        }
        $state.pendingNotifications = @()
        Save-QuietState -State $state -Path $StatePath
    } else {
        Write-Host "No pending notifications"
    }
}
