# 通知协调员 - 情境感知静默实现

param(
    [string]$Action = "check",
    [string]$Severity = "info",
    [string]$Message,
    [string]$Source,
    [string]$StatePath = "memory/quiet-mode-state.json"
)

$stateDir = Split-Path $StatePath -Parent
if (!(Test-Path $stateDir)) { New-Item -ItemType Directory -Force -Path $stateDir | Out-Null }

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

function Test-QuietHours {
    $now = Get-Date
    $startHour = [int]($state.quietSchedule.start -split ':')[0]
    $endHour = [int]($state.quietSchedule.end -split ':')[0]
    $currentHour = $now.Hour
    if ($startHour -gt $endHour) {
        return ($currentHour -ge $startHour -or $currentHour -lt $endHour)
    } else {
        return ($currentHour -ge $startHour -and $currentHour -lt $endHour)
    }
}

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

function Test-ShouldNotify {
    param([int]$SeverityLevel, [bool]$InQuietHours, [string]$UserStatus)
    if ($SeverityLevel -ge 4) { return $true }
    if ($InQuietHours) {
        if ($SeverityLevel -ge 3) { return $true } else { return $false }
    }
    switch ($UserStatus) {
        "active" { return $true }
        "away" { return $SeverityLevel -ge 2 }
        "busy" { return $SeverityLevel -ge 3 }
        default { return $true }
    }
}

$state = Get-QuietState -Path $StatePath
$inQuietHours = Test-QuietHours
$severityLevel = Get-SeverityLevel -Severity $Severity

if ($Action -eq "check") {
    Write-Host "currentMode:$($state.currentMode)"
    Write-Host "quietSchedule:$($state.quietSchedule.start)-$($state.quietSchedule.end)"
    Write-Host "inQuietHours:$inQuietHours"
    Write-Host "userStatus:$($state.userState.status)"
    Write-Host "pendingCount:$($state.pendingNotifications.Count)"
    Write-Host "stats:sent=$($state.statistics.today.sent),delayed=$($state.statistics.today.delayed),suppressed=$($state.statistics.today.suppressed)"
}
elseif ($Action -eq "send") {
    $shouldNotify = Test-ShouldNotify -SeverityLevel $severityLevel -InQuietHours $inQuietHours -UserStatus $state.userState.status
    if ($shouldNotify) {
        Write-Host "SEND"
        $state.statistics.today.sent++
        $state.statistics.thisWeek.sent++
    } else {
        Write-Host "QUEUE"
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
    if ($state.pendingNotifications.Count -gt 0) {
        Write-Host "FLUSH $($state.pendingNotifications.Count) notifications"
        $state.pendingNotifications | ForEach-Object {
            Write-Host "  - [$($_.severity)] $($_.source): $($_.message)"
        }
        $state.pendingNotifications = @()
        Save-QuietState -State $state -Path $StatePath
    } else {
        Write-Host "No pending notifications"
    }
}
