# OpenClaw Health Check & Security Audit Script
# Runs every 12 hours via Windows Task Scheduler
# Sends report to Telegram upon completion

$LogFile = "$env:USERPROFILE\.openclaw\logs\health-check.log"
$ReportFile = "$env:USERPROFILE\.openclaw\logs\health-check-report.txt"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$DateStr = Get-Date -Format "yyyy-MM-dd HH:mm"

# Telegram Bot Configuration
$BotToken = "8329757047:AAFxkpIJqkm-8HT1ZFz005tjFDeRRRIisH0"
$ChatId = "8542040756"

# Ensure log directory exists
$LogDir = Split-Path $LogFile -Parent
if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

function Write-Log {
    param([string]$Message)
    $LogLine = "$Timestamp - $Message"
    $LogLine | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

function Send-TelegramMessage {
    param([string]$Message)
    try {
        $Uri = "https://api.telegram.org/bot$BotToken/sendMessage"
        $Body = @{
            chat_id = $ChatId
            text = $Message
            parse_mode = "Markdown"
        } | ConvertTo-Json -Compress
        
        Invoke-RestMethod -Uri $Uri -Method Post -ContentType "application/json" -Body $Body -TimeoutSec 30 | Out-Null
    } catch {
        $ErrorMsg = $_.Exception.Message
        Write-Log "Failed to send Telegram message: $ErrorMsg"
    }
}

# Initialize Report Array
$ReportLines = @()
$ReportLines += "OpenClaw Health Check Report"
$ReportLines += "Time: $DateStr"
$ReportLines += ""

Write-Log "=== OpenClaw Health Check Started ==="

# 1. Gateway Status
Write-Log "Checking Gateway Status..."
try {
    $GatewayOutput = openclaw gateway status 2>&1 | Out-String
    $GatewayRunning = $GatewayOutput -match "running|active"
    if ($GatewayRunning) {
        Write-Log "Gateway Status: RUNNING"
        $ReportLines += "Gateway: RUNNING"
    } else {
        Write-Log "Gateway NOT RUNNING - Attempting restart"
        openclaw gateway start
        Start-Sleep -Seconds 5
        $RetryOutput = openclaw gateway status 2>&1 | Out-String
        $RestartSuccess = $RetryOutput -match "running|active"
        if ($RestartSuccess) {
            Write-Log "Gateway restarted successfully"
            $ReportLines += "Gateway: RESTARTED (was down)"
        } else {
            Write-Log "Gateway restart failed"
            $ReportLines += "Gateway: FAILED TO RESTART"
        }
    }
} catch {
    $ErrorMsg = $_.Exception.Message
    Write-Log "ERROR checking gateway: $ErrorMsg"
    $ReportLines += "Gateway: ERROR"
}
$ReportLines += ""

# 2. System Resources
Write-Log "Checking System Resources..."

# Disk Space
$Disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
$FreeSpaceGB = [math]::Round($Disk.FreeSpace / 1GB, 2)
$TotalSpaceGB = [math]::Round($Disk.Size / 1GB, 2)
$PercentFree = [math]::Round(($Disk.FreeSpace / $Disk.Size) * 100, 2)
if ($PercentFree -lt 10) { $DiskStatus = "LOW SPACE WARNING" } 
elseif ($PercentFree -lt 20) { $DiskStatus = "Low space" } 
else { $DiskStatus = "OK" }
Write-Log "Disk: $FreeSpaceGB GB free of $TotalSpaceGB GB"
$ReportLines += "Disk: $FreeSpaceGB GB / $TotalSpaceGB GB ($PercentFree% free) - $DiskStatus"

# Memory
$Memory = Get-WmiObject -Class Win32_OperatingSystem
$FreeMemoryGB = [math]::Round($Memory.FreePhysicalMemory / 1MB, 2)
$TotalMemoryGB = [math]::Round($Memory.TotalVisibleMemorySize / 1MB, 2)
$UsedMemoryGB = [math]::Round($TotalMemoryGB - $FreeMemoryGB, 2)
$MemoryPercent = [math]::Round(($UsedMemoryGB / $TotalMemoryGB) * 100, 1)
Write-Log "Memory: $FreeMemoryGB GB free of $TotalMemoryGB GB"
$ReportLines += "Memory: $UsedMemoryGB GB / $TotalMemoryGB GB ($MemoryPercent% used)"
$ReportLines += ""

# 3. Security Audit
Write-Log "Running Security Audit..."
$ReportLines += "Security Audit:"

# Check OpenClaw version
try {
    $VersionOutput = openclaw --version 2>&1
    Write-Log "Version: $VersionOutput"
    $ReportLines += "Version: $VersionOutput"
} catch {
    $ReportLines += "Version: check failed"
}

# Check config file
$ConfigPath = "$env:USERPROFILE\.openclaw\openclaw.json"
try {
    if (Test-Path $ConfigPath) {
        $Config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        Write-Log "Config check: VALID"
        $ReportLines += "Config: VALID"
        
        # Check for tokens
        $ConfigText = Get-Content $ConfigPath -Raw
        if ($ConfigText -match '"token"') {
            $ReportLines += "Note: Config contains tokens"
        }
    } else {
        Write-Log "Config file not found"
        $ReportLines += "Config: NOT FOUND"
    }
} catch {
    $ErrorMsg = $_.Exception.Message
    Write-Log "Config check error: $ErrorMsg"
    $ReportLines += "Config: ERROR"
}

# Check workspace
$WorkspacePath = "$env:USERPROFILE\.openclaw\workspace"
if (Test-Path $WorkspacePath) {
    $ReportLines += "Workspace: EXISTS"
} else {
    $ReportLines += "Workspace: MISSING"
}

$ReportLines += ""

# 4. Channel Status
Write-Log "Checking Channel Status..."
$ReportLines += "Channels:"
try {
    $StatusOutput = openclaw status 2>&1 | Out-String
    if ($StatusOutput -match "telegram") {
        $ReportLines += "Telegram: CONFIGURED"
    } else {
        $ReportLines += "Telegram: NOT DETECTED"
    }
} catch {
    $ReportLines += "Channels: check failed"
}
$ReportLines += ""

# 5. Summary
$ReportLines += "---"
$ReportLines += "Check completed. Next check: 12 hours"
$ReportLines += "Log: %USERPROFILE%\.openclaw\logs\health-check.log"

# Save report to file
$ReportContent = $ReportLines -join "`n"
$ReportContent | Out-File -FilePath $ReportFile -Encoding UTF8

# Send to Telegram
Write-Log "Sending report to Telegram..."
Send-TelegramMessage -Message $ReportContent

Write-Log "=== Health Check Completed ==="
Write-Log ""
