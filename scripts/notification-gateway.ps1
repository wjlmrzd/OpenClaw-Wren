# Notification Gateway for OpenClaw
# Handles intelligent notification management based on time and severity

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("get-mode", "send")]
    [string]$Action,
    
    [ValidateSet("info", "attention", "warning", "critical", "crisis")]
    [string]$Severity,
    
    [string]$Message
)

# Define paths
$notificationStateFile = "D:\OpenClaw\.openclaw\workspace\memory\notification-state.json"
$currentTime = Get-Date
$currentHour = $currentTime.Hour

# Determine current mode based on time
function Get-NotificationMode {
    if ($currentHour -ge 6 -and $currentHour -lt 9) {
        return "morning"  # 06:00-09:00
    }
    elseif (($currentHour -ge 9 -and $currentHour -lt 12) -or ($currentHour -ge 14 -and $currentHour -lt 18)) {
        return "working-hours"  # 09:00-12:00, 14:00-18:00
    }
    elseif ($currentHour -ge 18 -and $currentHour -lt 22) {
        return "evening"  # 18:00-22:00
    }
    else {
        return "sleep-time"  # 22:00-06:00 (includes overnight)
    }
}

# Ensure notification state file exists
if (!(Test-Path $notificationStateFile)) {
    $initialState = @{
        queue = @()
        lastUpdated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
    $initialState | ConvertTo-Json | Out-File -FilePath $notificationStateFile -Encoding UTF8
}

switch ($Action) {
    "get-mode" {
        $mode = Get-NotificationMode
        Write-Output $mode
    }
    
    "send" {
        if ([string]::IsNullOrEmpty($Severity) -or [string]::IsNullOrEmpty($Message)) {
            Write-Error "Severity and Message are required for send action"
            exit 1
        }
        
        # Determine if notification should be sent based on current mode and severity
        $currentMode = Get-NotificationMode
        $shouldSend = $false
        $actionResult = "QUEUE"
        
        switch ($currentMode) {
            "working-hours" {
                # All levels allowed during working hours
                $shouldSend = $true
                $actionResult = "SEND"
            }
            "morning" {
                # All levels allowed in morning
                $shouldSend = $true
                $actionResult = "SEND"
            }
            "evening" {
                # Only warning and above during evening
                if ($Severity -in @("warning", "critical", "crisis")) {
                    $shouldSend = $true
                    $actionResult = "SEND"
                }
            }
            "sleep-time" {
                # Only critical and crisis during sleep time
                if ($Severity -in @("critical", "crisis")) {
                    $shouldSend = $true
                    $actionResult = "SEND"
                }
            }
        }
        
        # Load current notification state
        $notificationState = Get-Content $notificationStateFile | ConvertFrom-Json -AsHashtable
        
        # Create notification object
        $notification = @{
            severity = $Severity
            message = $Message
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            shouldSend = $shouldSend
        }
        
        # Add to queue if not being sent immediately
        if ($actionResult -eq "QUEUE") {
            $notificationState.queue += $notification
        }
        
        # Update last updated time
        $notificationState.lastUpdated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        
        # Write updated state back to file
        $notificationState | ConvertTo-Json -Depth 10 | Out-File -FilePath $notificationStateFile -Encoding UTF8
        
        # Check if we need to flush the queue (more than 10 items)
        $queueCount = $notificationState.queue.Count
        if ($queueCount -gt 10) {
            $actionResult = "FLUSH"
            
            # Count severity types in queue
            $severityCounts = @{
                critical = 0
                crisis = 0
                warning = 0
                attention = 0
                info = 0
            }
            
            foreach ($item in $notificationState.queue) {
                if ($severityCounts.ContainsKey($item.severity)) {
                    $severityCounts[$item.severity]++
                }
            }
            
            # Generate summary
            Write-Output "🔔 通知队列摘要"
            Write-Output ""
            Write-Output "📊 累积通知：$queueCount 条"
            Write-Output "- 紧急：$([int]$severityCounts.critical) 条（已发送）"
            Write-Output "- 警告：$([int]$severityCounts.warning) 条"
            Write-Output "- 信息：$([int]$severityCounts.info) 条"
            Write-Output ""
            Write-Output "📋 详情：memory/notification-state.json"
        }
        
        Write-Output $actionResult
    }
}