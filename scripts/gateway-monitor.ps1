# OpenClaw Gateway Health Monitor v5
# Uses netstat + process + config checks (no external TCP probes needed)
# L1 Auto-Fix -> L2 Auto-Restart -> L3 Human Alert

param(
    [string]$Mode = "smart",
    [int]$MaxRestartsPerHour = 3,
    [int]$CooldownMinutes = 5
)

$ErrorActionPreference = "SilentlyContinue"
$LogFile = "$env:USERPROFILE\.openclaw\logs\monitor.log"
$StateFile = "$env:USERPROFILE\.openclaw\monitor-state.json"

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
        Invoke-RestMethod -Uri "$Url?chat_id=$ChatId&text=$EncodedText" -Method Get -TimeoutSec 10 | Out-Null
    } catch {
        Write-Log "Telegram failed: $_" "ERROR"
    }
}

# ========== HEALTH CHECKS ==========

function Test-GatewayHealth() {
    $Results = @{}

    # 1. Port check: TCP port 18789 listening
    # Uses netstat which is lightweight and never blocks
    try {
        $PortCheck = netstat -ano | Select-String "LISTENING" | Select-String "18789"
        if ($PortCheck) {
            # Extract PID from LISTENING line
            if ($PortCheck -match "\s(\d+)$") {
                $Results.Port = @{ Status = "OK"; PID = $matches[1] }
            } else {
                $Results.Port = @{ Status = "OK" }
            }
        } else {
            $Results.Port = @{ Status = "FAIL"; Error = "Port 18789 not listening" }
        }
    } catch {
        $Results.Port = @{ Status = "WARN"; Error = "netstat failed" }
    }

    # 2. Process check: node.exe with openclaw
    try {
        $Processes = Get-CimInstance Win32_Process -Filter "Name='node.exe'" 2>$null
        $OpenClawProc = $Processes | Where-Object { $_.CommandLine -like "*openclaw*" } | Select-Object -First 1
        if ($OpenClawProc) {
            $MemMB = [math]::Round($OpenClawProc.WorkingSetSize / 1MB, 2)
            $CPUChar = $OpenClawProc.ElapsedTime
            $Results.Process = @{ Status = "OK"; MemoryMB = $MemMB; PID = $OpenClawProc.ProcessId }
            if ($MemMB -gt 800) {
                $Results.Process.Status = "WARN"
                $Results.Process.Note = "High memory (${MemMB}MB)"
            }
            if ($MemMB -gt 1200) {
                $Results.Process.Status = "WARN"
                $Results.Process.Note = "Critical memory (${MemMB}MB)"
            }
        } else {
            $Results.Process = @{ Status = "FAIL"; Error = "No openclaw process found" }
        }
    } catch {
        $Results.Process = @{ Status = "WARN"; Error = "Process query failed" }
    }

    # 3. Config file: valid JSON
    try {
        $ConfigPath = "$env:USERPROFILE\.openclaw\openclaw.json"
        if (Test-Path $ConfigPath) {
            Get-Content $ConfigPath -Raw | ConvertFrom-Json | Out-Null
            $Results.Config = @{ Status = "OK" }
        } else {
            $Results.Config = @{ Status = "FAIL"; Error = "Config file missing" }
        }
    } catch {
        $Results.Config = @{ Status = "FAIL"; Error = "Invalid JSON" }
    }

    # 4. Gateway log file: recent activity (optional)
    try {
        $LogPath = "$env:USERPROFILE\.openclaw\logs\clawdbot-$(Get-Date -Format 'yyyy-MM-dd').log"
        if (Test-Path $LogPath) {
            $LastLine = Get-Content $LogPath -Tail 1 -ErrorAction SilentlyContinue
            if ($LastLine -match "\d{2}:\d{2}:\d{2}") {
                # Extract timestamp to check freshness
                $Results.Log = @{ Status = "OK"; LastLine = $LastLine.Substring(0, [Math]::Min(80, $LastLine.Length)) }
            }
        }
    } catch { }

    return $Results
}

# ========== AUTO-FIX ==========

function Invoke-L1Fix($Issue) {
    Write-Log "L1 fix attempt: $Issue" "WARN"
    if ($Issue -eq "config_error") {
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

# ========== AUTO-RESTART ==========

function Invoke-L2Restart() {
    Write-Log "L2 restart attempt" "WARN"
    $RestartCount = 0
    $LastRestartTicks = 0

    if (Test-Path $StateFile) {
        try {
            $State = Get-Content $StateFile | ConvertFrom-Json
            $RestartCount = [int]$State.RestartCount
            $LastRestartTicks = [long]$State.LastRestartTicks
        } catch { }
    }

    $NowTicks = (Get-Date).Ticks
    $OneHourAgo = $NowTicks - 36000000000
    if ($LastRestartTicks -lt $OneHourAgo) { $RestartCount = 0 }

    $CooldownTicks = $CooldownMinutes * 600000000
    if (($NowTicks - $LastRestartTicks) -lt $CooldownTicks -and $LastRestartTicks -gt 0) {
        Write-Log "In cooldown, skip restart" "INFO"
        return $false
    }
    if ($RestartCount -ge $MaxRestartsPerHour) {
        Write-Log "Restart limit reached ($MaxRestartsPerHour/hr)" "ERROR"
        return $false
    }

    # Use openclaw-cn gateway restart (non-blocking approach)
    try {
        $nodeExe = 'C:\Program Files\nodejs\node.exe'
        $entryJs = 'C:\Users\Administrator\AppData\Roaming\npm\node_modules\openclaw-cn\dist\entry.js'
        Start-Process -FilePath $nodeExe -ArgumentList "`"$entryJs`"","gateway","restart" -NoNewWindow -WindowStyle Hidden
        Start-Sleep -Seconds 15

        # Verify with port check (non-blocking)
        $Health = Test-GatewayHealth
        if ($Health.Port.Status -eq "OK") {
            $NewState = @{ LastRestartTicks = $NowTicks; RestartCount = $RestartCount + 1 }
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

# ========== ALERT ==========

function Invoke-L3Alert($Details) {
    Write-Log "L3 ALERT: $Details" "ERROR"
    $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Send-Telegram "ALERT [$Time] Gateway needs help. Issues: $Details"
}

# ========== MAIN ==========
Write-Log "Monitor started (Mode: $Mode)" "INFO"

$Health = Test-GatewayHealth
$Issues = @()

# Determine issues
if ($Health.Port.Status -eq "FAIL") { $Issues += "port_down" }
if ($Health.Process.Status -eq "FAIL") { $Issues += "process_dead" }
if ($Health.Process.Status -eq "WARN") {
    if ($Health.Process.Note -match "Critical") { $Issues += "memory_critical" }
    else { $Issues += "memory_high" }
}
if ($Health.Config.Status -ne "OK") { $Issues += "config_error" }

# All good
if ($Issues.Count -eq 0) {
    $StatusDetail = "Port: OK, Process: OK"
    if ($Health.Process.MemoryMB) { $StatusDetail += ", Mem: $($Health.Process.MemoryMB)MB" }
    if ($Health.Log.Status -eq "OK") { $StatusDetail += ", Log OK" }
    $StatusDetail += ", Config: OK"
    Write-Log "All checks passed ($StatusDetail)" "INFO"
    exit 0
}

Write-Log "Issues: $($Issues -join ', ')" "WARN"

# Log detail for debugging
foreach ($Key in $Health.Keys) {
    $Err = $Health.$Key.Error
    if ($Err) { Write-Log "  $Key error: $Err" "WARN" }
}

$Fixed = $false

# L1: Try auto-fix
foreach ($Issue in $Issues) {
    if (Invoke-L1Fix $Issue) { $Fixed = $true; break }
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
