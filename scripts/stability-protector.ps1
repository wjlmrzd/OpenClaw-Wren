# OpenClaw Stability Protection Mechanism

param(
    [string]$Action = "check",
    [switch]$Verbose
)

$workspaceRoot = "D:\OpenClaw\.openclaw\workspace"
$openclawRoot = "D:\OpenClaw\.openclaw"
$statePath = Join-Path $workspaceRoot "memory\stability-state.json"
$tokenHistoryPath = Join-Path $workspaceRoot "memory\token-usage-history.json"

# High-load task IDs
$highLoadTasks = @(
    "c73f1ecf-9f61-47c5-bea1-1c4f322e2ebe",
    "af025901-6ebc-4541-9698-91c5db9907e6",
    "53b6edc8-7cc6-4900-ab41-d1abd3e1e15f",
    "2b564e59-8ed9-4cd8-8345-a9b41e4349bb"
)

function Get-StabilityState {
    if (Test-Path $statePath) {
        return Get-Content $statePath | ConvertFrom-Json
    }
    return @{
        currentMode = "normal"
        activeHighLoadTask = $null
        taskQueue = @()
        lastMaintenance = $null
        healerStormProtection = @{
            windowStart = $null
            repairCount = 0
            maxRepairsPerWindow = 3
            windowMinutes = 10
        }
        tokenPrediction = @{
            lastCheck = $null
            predicted6h = 0
            trend = "stable"
        }
    }
}

function Save-StabilityState {
    param($state)
    $state | ConvertTo-Json -Depth 10 | Set-Content $statePath -Encoding UTF8
}

function Test-HighLoadTaskRunning {
    $state = Get-StabilityState
    if ($state.activeHighLoadTask) {
        try {
            $cronOutput = & openclaw cron list 2>&1 | Out-String
            if ($cronOutput -match $state.activeHighLoadTask) {
                return $true
            }
        } catch {}
        $state.activeHighLoadTask = $null
        Save-StabilityState -state $state
    }
    return $false
}

function Process-TaskQueue {
    $state = Get-StabilityState
    
    if (-not $state.taskQueue -or $state.taskQueue.Count -eq 0) {
        return
    }
    
    if (-not (Test-HighLoadTaskRunning)) {
        $nextTask = $state.taskQueue[0]
        $state.taskQueue = $state.taskQueue[1..($state.taskQueue.Count-1)]
        Save-StabilityState -state $state
        
        Write-Host "Processing queued task: $($nextTask.taskName)" -ForegroundColor Cyan
    }
}

function Predict-TokenUsage {
    $history = @{ history = @(); lastUpdate = $null }
    
    if (Test-Path $tokenHistoryPath) {
        $history = Get-Content $tokenHistoryPath | ConvertFrom-Json
    }
    
    if (-not $history.history -or $history.history.Count -lt 10) {
        return @{
            predicted6h = 0
            confidence = "low"
            trend = "unknown"
        }
    }
    
    $now = Get-Date
    $sixHoursAgo = $now.AddHours(-6)
    
    $recentUsage = $history.history | Where-Object {
        [datetime]$_.timestamp -gt $sixHoursAgo
    }
    
    if ($recentUsage.Count -eq 0) {
        $avgPerHour = ($history.history | Measure-Object -Property tokens -Average).Average
        $predicted6h = $avgPerHour * 6
    } else {
        $predicted6h = ($recentUsage | Measure-Object -Property tokens -Sum).Sum
    }
    
    $trend = "stable"
    
    return @{
        predicted6h = [math]::Round($predicted6h, 0)
        confidence = "medium"
        trend = $trend
    }
}

function Test-HealerStormProtection {
    $state = Get-StabilityState
    $protection = $state.healerStormProtection
    $now = Get-Date
    
    if ($protection.windowStart) {
        $windowStart = [datetime]$protection.windowStart
        $windowEnd = $windowStart.AddMinutes($protection.windowMinutes)
        
        if ($now -gt $windowEnd) {
            Write-Host "Healer storm protection window reset" -ForegroundColor Gray
            $protection.windowStart = $now.ToString("yyyy-MM-ddTHH:mm:ssZ")
            $protection.repairCount = 0
            $state.healerStormProtection = $protection
            Save-StabilityState -state $state
            return $true
        }
    } else {
        $protection.windowStart = $now.ToString("yyyy-MM-ddTHH:mm:ssZ")
        $protection.repairCount = 0
        $state.healerStormProtection = $protection
        Save-StabilityState -state $state
    }
    
    if ($protection.repairCount -ge $protection.maxRepairsPerWindow) {
        Write-Host "Healer storm protection triggered! Limit reached" -ForegroundColor Red
        return $false
    }
    
    return $true
}

# Main execution
Write-Host "=== OpenClaw Stability Protector ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

$state = Get-StabilityState

if ($Action -eq "check") {
    Write-Host "[Checking stability status...]" -ForegroundColor Yellow
    
    $running = Test-HighLoadTaskRunning
    if ($running) {
        Write-Host "  High-load task running: YES - $($state.activeHighLoadTask)" -ForegroundColor Yellow
    } else {
        Write-Host "  High-load task running: NO" -ForegroundColor Green
    }
    
    $queueCount = 0
    if ($state.taskQueue) {
        $queueCount = $state.taskQueue.Count
    }
    if ($queueCount -gt 0) {
        Write-Host "  Task queue: $queueCount tasks waiting" -ForegroundColor Yellow
    } else {
        Write-Host "  Task queue: Empty" -ForegroundColor Green
    }
    
    $prediction = Predict-TokenUsage
    $tokenColor = "Green"
    if ($prediction.predicted6h -gt 800000) {
        $tokenColor = "Red"
    } elseif ($prediction.predicted6h -gt 500000) {
        $tokenColor = "Yellow"
    }
    Write-Host "  Token prediction (6h): $($prediction.predicted6h) ($($prediction.trend))" -ForegroundColor $tokenColor
    
    $protection = $state.healerStormProtection
    $windowStart = $null
    $windowEnd = $null
    if ($protection.windowStart) {
        $windowStart = [datetime]$protection.windowStart
        $windowEnd = $windowStart.AddMinutes($protection.windowMinutes)
    }
    
    $windowStr = "Not active"
    if ($windowEnd) {
        $windowStr = $windowEnd.ToString("HH:mm")
    }
    
    $protColor = "Green"
    if ($protection.repairCount -ge 3) {
        $protColor = "Red"
    }
    Write-Host "  Healer storm protection: $($protection.repairCount)/$($protection.maxRepairsPerWindow) (window: $windowStr)" -ForegroundColor $protColor
    
    $maintStr = "Not executed"
    if ($state.lastMaintenance) {
        $maintStr = $state.lastMaintenance
    }
    Write-Host "  Last maintenance: $maintStr" -ForegroundColor Gray
    
    if ($queueCount -gt 0) {
        Write-Host ""
        Write-Host "[Processing task queue...]" -ForegroundColor Cyan
        Process-TaskQueue
    }
}
elseif ($Action -eq "predict") {
    Write-Host "[Token usage prediction...]" -ForegroundColor Yellow
    $prediction = Predict-TokenUsage
    Write-Host "  Predicted 6h: $($prediction.predicted6h) tokens" -ForegroundColor Cyan
    Write-Host "  Trend: $($prediction.trend)" -ForegroundColor Yellow
    Write-Host "  Confidence: $($prediction.confidence)" -ForegroundColor Gray
}
elseif ($Action -eq "maintenance") {
    Write-Host "Running daily maintenance..." -ForegroundColor Cyan
    $state = Get-StabilityState
    $state.lastMaintenance = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    Save-StabilityState -state $state
    Write-Host "Maintenance completed" -ForegroundColor Green
}
elseif ($Action -eq "status") {
    $state | ConvertTo-Json -Depth 10
}
else {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\stability-protector.ps1 -Action check       # Check status" -ForegroundColor Gray
    Write-Host "  .\stability-protector.ps1 -Action predict     # Token prediction" -ForegroundColor Gray
    Write-Host "  .\stability-protector.ps1 -Action maintenance # Daily maintenance" -ForegroundColor Gray
    Write-Host "  .\stability-protector.ps1 -Action status      # Output status JSON" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Complete ===" -ForegroundColor Cyan
