# OpenClaw Gateway Smart Monitor (Plan 3)
# L1 Auto-Fix -> L2 Auto-Restart -> L3 Human Alert

param(
    [string]$Mode = "smart",
    [int]$MaxRestartsPerHour = 3,
    [int]$CooldownMinutes = 5
)

$ErrorActionPreference = "SilentlyContinue"
$LogFile = "$env:USERPROFILE\.openclaw\logs\monitor.log"
$StateFile = "$env:USERPROFILE\.openclaw\monitor-state.json"

# Ensure log directory
$LogDir = Split-Path $LogFile -Parent
if (!(Test-Path $LogDir)) { 
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null 
}

function Write-Log($Message, $Level = "INFO") {
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $LogEntry -ErrorAction SilentlyContinue
    Write-Host $LogEntry
}

function Send-Telegram($Text) {
    $BotToken = "8329757047:AAEas5LRhvSSGBY6t0zsHzyV8nv_8CZyczA"
    $ChatId = "8542040756"
    
    try {
        $Url = "https://api.telegram.org/bot$BotToken/sendMessage"
        $EncodedText = [System.Uri]::EscapeDataString($Text)
        $FullUrl = "$Url?chat_id=$ChatId&text=$EncodedText"
        Invoke-RestMethod -Uri $FullUrl -Method Get -TimeoutSec 10 | Out-Null
    } catch {
        Write-Log "Telegram failed: $_" "ERROR"
    }
}

# Health check
function Test-GatewayHealth() {
    $Results = @{}
    
    # Check API
    try {
        $Response = Invoke-RestMethod -Uri "http://127.0.0.1:18789/status" -TimeoutSec 5
        $Results.Api = @{ Status = "OK" }
    } catch {
        $Results.Api = @{ Status = "FAIL"; Error = $_.Exception.Message }
    }
    
    # Check process
    try {
        $Process = Get-Process -Name "node" | Where-Object { $_.CommandLine -like "*openclaw*" } | Select-Object -First 1
        if ($Process) {
            $MemMB = [math]::Round($Process.WorkingSet64 / 1MB, 2)
            $Results.Memory = @{ Status = "OK"; WorkingSetMB = $MemMB }
            # Warn if memory > 500MB
            if ($MemMB -gt 500) {
                $Results.Memory.Status = "WARN"
            }
        } else {
            $Results.Memory = @{ Status = "FAIL"; Error = "Process not found" }
        }
    } catch {
        $Results.Memory = @{ Status = "FAIL"; Error = $_.Exception.Message }
    }
    
    # Check config
    try {
        $ConfigPath = "$env:USERPROFILE\.openclaw\openclaw.json"
        Get-Content $ConfigPath -Raw | ConvertFrom-Json | Out-Null
        $Results.Config = @{ Status = "OK" }
    } catch {
        $Results.Config = @{ Status = "FAIL"; Error = "Invalid JSON" }
    }
    
    return $Results
}

# L1 Auto-fix
function Invoke-L1Fix($Issue) {
    Write-Log "L1 fix attempt: $Issue" "WARN"
    
    if ($Issue -eq "config_syntax_error") {
        $BackupPath = "$env:USERPROFILE\.openclaw\openclaw.json.bak"
        $ConfigPath = "$env:USERPROFILE\.openclaw\openclaw.json"
        if (Test-Path $BackupPath) {
            Copy-Item $BackupPath $ConfigPath -Force
            Write-Log "Config restored from backup" "INFO"
            return $true
        }
    }
    return $false
}

# L2 Auto-restart
function Invoke-L2Restart() {
    Write-Log "L2 restart attempt" "WARN"
    
    # Load state
    $RestartCount = 0
    $LastRestartTicks = 0
    
    if (Test-Path $StateFile) {
        try {
            $State = Get-Content $StateFile | ConvertFrom-Json
            $RestartCount = [int]$State.RestartCount
            $LastRestartTicks = [long]$State.LastRestartTicks
        } catch {
            # Invalid state file, reset
            $RestartCount = 0
            $LastRestartTicks = 0
        }
    }
    
    $NowTicks = (Get-Date).Ticks
    $OneHourAgo = $NowTicks - 36000000000  # 1 hour in ticks
    
    # Reset count if last restart was over an hour ago
    if ($LastRestartTicks -lt $OneHourAgo) {
        $RestartCount = 0
    }
    
    # Check cooldown
    $CooldownTicks = $CooldownMinutes * 600000000  # minutes to ticks
    if (($NowTicks - $LastRestartTicks) -lt $CooldownTicks -and $LastRestartTicks -gt 0) {
        Write-Log "In cooldown, skip restart" "INFO"
        return $false
    }
    
    # Check limit
    if ($RestartCount -ge $MaxRestartsPerHour) {
        Write-Log "Restart limit reached ($MaxRestartsPerHour/hr)" "ERROR"
        return $false
    }
    
    # Execute restart
    try {
        & openclaw-cn gateway restart
        Start-Sleep -Seconds 10
        
        # Verify
        $Health = Test-GatewayHealth
        if ($Health.Api.Status -eq "OK") {
            # Save state
            $NewState = @{
                LastRestartTicks = $NowTicks
                RestartCount = $RestartCount + 1
            }
            $NewState | ConvertTo-Json | Set-Content $StateFile
            
            Write-Log "Restart successful" "INFO"
            Send-Telegram "Gateway auto-restarted OK (count: $($RestartCount + 1)/$MaxRestartsPerHour hr)"
            return $true
        }
    } catch {
        Write-Log "Restart failed: $_" "ERROR"
    }
    
    return $false
}

# L3 Alert
function Invoke-L3Alert($Details) {
    Write-Log "L3 ALERT: $Details" "ERROR"
    $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Alert = "ALERT [$Time] Gateway needs help. Issues: $Details. Log: $LogFile"
    Send-Telegram $Alert
}

# ========== MAIN ==========
Write-Log "Monitor started (Mode: $Mode)" "INFO"

$Health = Test-GatewayHealth
$Issues = @()

# Collect issues
if ($Health.Api.Status -ne "OK") { $Issues += "api_unresponsive" }
if ($Health.Memory.Status -eq "FAIL") { $Issues += "process_dead" }
if ($Health.Memory.Status -eq "WARN") { $Issues += "memory_high" }
if ($Health.Config.Status -ne "OK") { $Issues += "config_error" }

# All good
if ($Issues.Count -eq 0) {
    Write-Log "All checks passed (Memory: $($Health.Memory.WorkingSetMB) MB)" "INFO"
    exit 0
}

Write-Log "Issues: $($Issues -join ', ')" "WARN"

$Fixed = $false

# L1: Try auto-fix
foreach ($Issue in $Issues) {
    if (Invoke-L1Fix $Issue) {
        $Fixed = $true
        break
    }
}

# L2: Try restart (unless conservative mode)
if (-not $Fixed -and $Mode -ne "conservative") {
    $Fixed = Invoke-L2Restart
}

# L3: Alert if not fixed
if (-not $Fixed) {
    Invoke-L3Alert ($Issues -join ", ")
}

Write-Log "Monitor cycle complete" "INFO"
