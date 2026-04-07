# Notification Gateway for OpenClaw
# Handles intelligent notification management based on time and severity

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("get-mode", "send", "check-queue")]
    [string]$Action,
    
    [ValidateSet("info", "attention", "warning", "critical", "crisis")]
    [string]$Severity,
    
    [string]$Message
)

$notificationStateFile = "D:\OpenClaw\.openclaw\workspace\memory\notification-state.json"
$currentTime = Get-Date
$currentHour = $currentTime.Hour

function Get-NotificationMode {
    if ($currentHour -ge 6 -and $currentHour -lt 9) {
        return "morning"
    }
    elseif (($currentHour -ge 9 -and $currentHour -lt 12) -or ($currentHour -ge 14 -and $currentHour -lt 18)) {
        return "working-hours"
    }
    elseif ($currentHour -ge 18 -and $currentHour -lt 22) {
        return "evening"
    }
    else {
        return "sleep-time"
    }
}

if (!(Test-Path $notificationStateFile)) {
    $initialState = @{
        queue = @()
        lastUpdated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
    $initialState | ConvertTo-Json -Encoding UTF8 | Out-File -FilePath $notificationStateFile -Encoding UTF8
}

switch ($Action) {
    "get-mode" {
        Write-Output (Get-NotificationMode)
    }
    
    "send" {
        if ([string]::IsNullOrEmpty($Severity) -or [string]::IsNullOrEmpty($Message)) {
            Write-Error "Severity and Message are required"
            exit 1
        }
        $currentMode = Get-NotificationMode
        $shouldSend = $false
        $actionResult = "QUEUE"
        
        switch ($currentMode) {
            "working-hours" { $shouldSend = $true; $actionResult = "SEND" }
            "morning" { $shouldSend = $true; $actionResult = "SEND" }
            "evening" { if ($Severity -in @("warning","critical","crisis")) { $shouldSend = $true; $actionResult = "SEND" } }
            "sleep-time" { if ($Severity -in @("critical","crisis")) { $shouldSend = $true; $actionResult = "SEND" } }
        }
        
        $rawJson = Get-Content $notificationStateFile -Raw
        $notificationState = $rawJson | ConvertFrom-Json
        
        $notification = @{
            severity = $Severity
            message = $Message
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            shouldSend = $shouldSend
        }
        
        if ($actionResult -eq "QUEUE") {
            if ($null -eq $notificationState.queue) { $notificationState.queue = @() }
            $notificationState.queue += $notification
        }
        
        $notificationState.lastUpdated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $notificationState | ConvertTo-Json -Depth 10 | Out-File -FilePath $notificationStateFile -Encoding UTF8
        
        if ($notificationState.queue.Count -gt 10) { Write-Output "FLUSH" }
        Write-Output $actionResult
    }
    
    "check-queue" {
        if (Test-Path $notificationStateFile) {
            $rawJson = Get-Content $notificationStateFile -Raw
            if ($rawJson -and $rawJson.Trim()) {
                try {
                    $state = $rawJson | ConvertFrom-Json
                    if ($null -ne $state) {
                        Add-Member -InputObject $state -MemberType NoteProperty -Name "currentMode" -Value (Get-NotificationMode) -Force
                        $state | ConvertTo-Json -Depth 10
                    } else {
                        Write-Output "{}"
                    }
                } catch {
                    Write-Output "{}"
                }
            } else {
                Write-Output "{}"
            }
        } else {
            @{
                queue = @()
                currentMode = (Get-NotificationMode)
                statistics = @{ today = @{ queued = 0; sent = 0; suppressed = 0 } }
            } | ConvertTo-Json -Depth 10
        }
    }
}
