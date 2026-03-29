# OpenClaw Health Check v2 - Sends Telegram Report
$LogDir = "$env:USERPROFILE\.openclaw\logs"
$LogFile = "$LogDir\health-check.log"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"

# Telegram Config
$BotToken = "8329757047:AAFxkpIJqkm-8HT1ZFz005tjFDeRRRIisH0"
$ChatId = "8542040756"

# Ensure log directory exists
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

# Helper: Write to log
function Write-Log($msg) {
    "$Timestamp - $msg" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# Helper: Send Telegram message
function Send-Telegram($text) {
    try {
        $uri = "https://api.telegram.org/bot$BotToken/sendMessage"
        $body = @{ chat_id = $ChatId; text = $text } | ConvertTo-Json -Compress
        Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json" -Body $body -TimeoutSec 30 | Out-Null
        Write-Log "Telegram report sent successfully"
    } catch {
        Write-Log "Failed to send Telegram: $($_.Exception.Message)"
    }
}

Write-Log "=== Health Check Started ==="

# Build report
$report = @()
$report += "📊 OpenClaw Health Check Report"
$report += "⏰ Time: $Timestamp"
$report += ""

# 1. Check Gateway
Write-Log "Checking gateway status..."
try {
    $gwStatus = & openclaw gateway status 2>&1
    if ($gwStatus -match "running|active") {
        $report += "✅ Gateway: RUNNING"
        Write-Log "Gateway: RUNNING"
    } else {
        $report += "⚠️ Gateway: NOT RUNNING - Attempting restart..."
        Write-Log "Gateway: NOT RUNNING - Restarting..."
        & openclaw gateway start | Out-Null
        Start-Sleep -Seconds 3
        $retry = & openclaw gateway status 2>&1
        if ($retry -match "running|active") {
            $report += "✅ Gateway: RESTARTED SUCCESSFULLY"
            Write-Log "Gateway: RESTARTED"
        } else {
            $report += "❌ Gateway: RESTART FAILED"
            Write-Log "Gateway: RESTART FAILED"
        }
    }
} catch {
    $report += "❌ Gateway: CHECK ERROR"
    Write-Log "Gateway check error: $_"
}
$report += ""

# 2. System Resources
Write-Log "Checking system resources..."

# Disk
$disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
$totalGB = [math]::Round($disk.Size / 1GB, 2)
$percentFree = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 1)
$diskStatus = if ($percentFree -lt 10) { "🔴 CRITICAL" } elseif ($percentFree -lt 20) { "🟡 LOW" } else { "🟢 OK" }
$report += "💾 Disk: $freeGB GB / $totalGB GB ($percentFree% free) $diskStatus"
Write-Log "Disk: $freeGB GB free of $totalGB GB"

# Memory
$mem = Get-WmiObject -Class Win32_OperatingSystem
$totalMem = [math]::Round($mem.TotalVisibleMemorySize / 1MB, 2)
$freeMem = [math]::Round($mem.FreePhysicalMemory / 1MB, 2)
$usedMem = [math]::Round($totalMem - $freeMem, 2)
$memPercent = [math]::Round(($usedMem / $totalMem) * 100, 1)
$report += "🧠 Memory: $usedMem GB / $totalMem GB ($memPercent% used)"
Write-Log "Memory: $usedMem GB used of $totalMem GB"
$report += ""

# 3. Security Audit
Write-Log "Running security audit..."
$report += "🔒 Security Audit:"

# Config check
$configPath = "$env:USERPROFILE\.openclaw\openclaw.json"
if (Test-Path $configPath) {
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        $report += "  ✅ Config: Valid JSON"
        Write-Log "Config: Valid"
    } catch {
        $report += "  ❌ Config: Invalid JSON"
        Write-Log "Config: Invalid"
    }
} else {
    $report += "  ❌ Config: Not found"
    Write-Log "Config: Not found"
}

# Workspace check
$workspacePath = "$env:USERPROFILE\.openclaw\workspace"
if (Test-Path $workspacePath) {
    $report += "  ✅ Workspace: Exists"
} else {
    $report += "  ❌ Workspace: Missing"
}
$report += ""

# 4. Summary
$report += "---"
$report += "📋 Check completed. Next check: 12 hours"
$report += "📝 Log: $LogFile"

# Send report
$reportText = $report -join "`n"
Send-Telegram -text $reportText

Write-Log "=== Health Check Completed ==="
Write-Log ""
