# Scheduler Optimizer - Auto-execute cron collision mitigation
param(
    [switch]$AnalyzeOnly,
    [switch]$AutoExecute,
    [int]$MaxChangesPerRun = 3
)

$ErrorActionPreference = "Continue"
$workspaceRoot = "D:\OpenClaw\.openclaw\workspace"
$cronJobsPath = "D:\OpenClaw\.openclaw\cron\jobs.json"
$statePath = Join-Path $workspaceRoot "memory\scheduler-state.json"

Write-Host "=== Scheduler Optimizer ===" -ForegroundColor Cyan
Write-Host "[1/6] Reading job config..." -ForegroundColor Yellow

# Use .NET UTF-8 reader to avoid PowerShell 5.1 encoding issues with Chinese chars in JSON
$jobsJson = [System.IO.File]::ReadAllText($cronJobsPath, [System.Text.Encoding]::UTF8)
$jobsData = $jobsJson | ConvertFrom-Json
$jobs = $jobsData.jobs
Write-Host ("  Total jobs: {0}" -f $jobs.Count) -ForegroundColor Gray

Write-Host "[2/6] Parsing cron expressions..." -ForegroundColor Yellow

function Parse-CronExpr($expr) {
    $parts = $expr -split '\s+'
    if ($parts.Count -lt 5) { return @() }

    $minute = $parts[0]
    $hour   = $parts[1]

    $minutes = @()
    if ($minute -eq '*') {
        $minutes = @(0..59)
    } elseif ($minute -match '^\*/(\d+)$') {
        $step = [int]$matches[1]
        for ($i = 0; $i -lt 60; $i += $step) { $minutes += $i }
    } elseif ($minute -match '^(\d+)-(\d+)$') {
        for ($i = [int]$matches[1]; $i -le [int]$matches[2]; $i++) { $minutes += $i }
    } elseif ($minute -match '^(\d+),(\d+)') {
        $minutes = [int[]] ($minute -split ',')
    } else {
        $minutes = @([int]$minute)
    }

    $hours = @()
    if ($hour -eq '*') {
        $hours = @(0..23)
    } elseif ($hour -match '^\*/(\d+)$') {
        $step = [int]$matches[1]
        for ($i = 0; $i -lt 24; $i += $step) { $hours += $i }
    } elseif ($hour -match '^(\d+)-(\d+)$') {
        for ($i = [int]$matches[1]; $i -le [int]$matches[2]; $i++) { $hours += $i }
    } elseif ($hour -match '^\*/(\d+)\s') {
        $step = [int]($hour -replace '^\*/', '')
        for ($i = 0; $i -lt 24; $i += $step) { $hours += $i }
    } elseif ($hour -match '^(\d+),(\d+)') {
        $hours = [int[]] ($hour -split ',')
    } else {
        $hours = @([int]$hour)
    }

    $result = @()
    foreach ($h in $hours) {
        foreach ($m in $minutes) {
            $result += "{0:D2}:{1:D2}" -f $h, $m
        }
    }
    return $result
}

$timeSlots = @{}
foreach ($job in $jobs) {
    if ($job.enabled -ne $true) { continue }
    $expr = $job.schedule.expr
    $times = Parse-CronExpr $expr
    $timeout = $job.payload.timeoutSeconds
    $isHeavy = ($timeout -gt 180)

    foreach ($t in $times) {
        if (-not $timeSlots.ContainsKey($t)) { $timeSlots[$t] = @() }
        $timeSlots[$t] += @{
            id      = $job.id
            name    = $job.name
            expr    = $expr
            timeout = $timeout
            isHeavy = $isHeavy
        }
    }
}

Write-Host ("  Parsed {0} time slots" -f $timeSlots.Count) -ForegroundColor Gray

Write-Host "[3/6] Detecting collision risk..." -ForegroundColor Yellow

$highRiskSlots = @()
$mediumRiskSlots = @()

foreach ($slot in $timeSlots.Keys) {
    $tasks = $timeSlots[$slot]
    if ($tasks.Count -ge 4) {
        $highRiskSlots += $slot
    } elseif ($tasks.Count -ge 3) {
        $heavyCount = ($tasks | Where-Object { $_.isHeavy }).Count
        if ($heavyCount -ge 2) {
            $highRiskSlots += $slot
        } else {
            $mediumRiskSlots += $slot
        }
    }
}

$highCount = $highRiskSlots.Count
$mediumCount = $mediumRiskSlots.Count

$highColor = if ($highCount -gt 0) { "Red" } else { "Green" }
$medColor  = if ($mediumCount -gt 0) { "Yellow" } else { "Green" }

Write-Host ("  HIGH risk: {0} slots" -f $highCount) -ForegroundColor $highColor
Write-Host ("  MEDIUM risk: {0} slots" -f $mediumCount) -ForegroundColor $medColor

Write-Host "[4/6] Generating optimization plan..." -ForegroundColor Yellow

$plannedChanges = @()

foreach ($slot in ($highRiskSlots + $mediumRiskSlots)) {
    $tasks = $timeSlots[$slot]
    $hour = [int]($slot -split ':')[0]

    $movable = $tasks | Where-Object {
        $tMinute = [int](($_.expr -split '\s+')[0])
        (($tMinute % 5) -eq 0) -and ($tasks.Count -gt 1)
    }

    $sorted = $movable | Sort-Object { -$_.timeout }
    $toMove = $sorted | Select-Object -Skip 1

    $offset = 5
    foreach ($task in $toMove) {
        if ($plannedChanges.Count -ge $MaxChangesPerRun) { break }

        $parts = ($task.expr -split '\s+')
        $oldMinute = [int]$parts[0]
        $newMinute = $oldMinute + $offset
        if ($newMinute -ge 60) {
            $newMinute = $newMinute - 60
            $offset = 1
        }

        $newSlot = "{0:D2}:{1:D2}" -f $hour, $newMinute
        $newCount = if ($timeSlots.ContainsKey($newSlot)) { $timeSlots[$newSlot].Count } else { 0 }

        if ($newCount -le 1) {
            $parts[0] = $newMinute.ToString()
            $newExpr = $parts -join ' '

            $plannedChanges += @{
                taskId   = $task.id
                taskName = $task.name
                oldExpr  = $task.expr
                newExpr  = $newExpr
                oldSlot  = $slot
                newSlot  = $newSlot
                reason   = "reduce_collision"
            }
            $msg = "  -> {0}: {1} -> {2}" -f $task.name, $slot, $newSlot
            Write-Host $msg -ForegroundColor Yellow
        }
    }
}

Write-Host ("  Planned changes: {0} tasks" -f $plannedChanges.Count) -ForegroundColor Gray

Write-Host "[5/6] Applying changes..." -ForegroundColor Yellow

$appliedChanges = @()
$failedChanges = @()
$cliPath = "openclaw"

foreach ($change in $plannedChanges) {
    if ($AnalyzeOnly) {
        Write-Host ("  [ANALYZE-ONLY] Skip: {0}" -f $change.taskName) -ForegroundColor Cyan
        continue
    }

    try {
        $result = & $cliPath cron update $change.taskId --schedule $change.newExpr 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host ("  OK {0}: {1} -> {2}" -f $change.taskName, $change.oldSlot, $change.newSlot) -ForegroundColor Green
            $appliedChanges += @{
                taskId   = $change.taskId
                taskName = $change.taskName
                oldExpr  = $change.oldExpr
                newExpr  = $change.newExpr
                oldSlot  = $change.oldSlot
                newSlot  = $change.newSlot
                status   = "success"
                appliedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
            }
        } else {
            Write-Host ("  FAIL {0}: {1}" -f $change.taskName, $result) -ForegroundColor Red
            $failedChanges += $change
        }
    } catch {
        Write-Host ("  ERROR {0}: {1}" -f $change.taskName, $_.Exception.Message) -ForegroundColor Red
        $failedChanges += $change
    }
}

Write-Host "[6/6] Updating state file..." -ForegroundColor Yellow

$existingState = @{}
if (Test-Path $statePath) {
    try {
        $raw = [System.IO.File]::ReadAllText($statePath, [System.Text.Encoding]::UTF8)
        $existingState = $raw | ConvertFrom-Json
    } catch { $existingState = @{} }
}

$history = @()
if ($existingState.optimizationHistory) {
    $history = @($existingState.optimizationHistory)
}

if ($appliedChanges.Count -gt 0) {
    $detailParts = $appliedChanges | ForEach-Object { "$($_.taskName) $($_.oldSlot)->$($_.newSlot)" }
    $history += @{
        date    = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss+08:00")
        action  = "auto_staggered_scheduling"
        details = ("Adjusted {0} tasks: {1}" -f $appliedChanges.Count, ($detailParts -join ', '))
    }
}

$newState = @{
    lastAnalysisAt       = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss+08:00")
    analysisCycle        = if ($existingState.analysisCycle) { $existingState.analysisCycle + 1 } else { 1 }
    totalTasks           = $jobs.Count
    highRiskSlots        = $highCount
    mediumRiskSlots      = $mediumCount
    plannedChanges       = $plannedChanges.Count
    appliedChanges       = $appliedChanges.Count
    failedChanges        = $failedChanges.Count
    optimizationHistory  = $history
    riskLevel            = if ($highCount -gt 0) { "HIGH" } elseif ($mediumCount -gt 0) { "MEDIUM" } else { "LOW" }
    recommendation       = if ($highCount -gt 0) { ("CRITICAL: {0} HIGH-risk slots" -f $highCount) } elseif ($mediumCount -gt 0) { ("WARN: {0} MEDIUM-risk slots" -f $mediumCount) } else { "OK: No collision risks" }
}

$newState | ConvertTo-Json -Depth 10 | Set-Content -Path $statePath -Encoding UTF8

Write-Host ""
Write-Host "=== Optimization Complete ===" -ForegroundColor Cyan
Write-Host ("  HIGH risk: {0}" -f $highCount) -ForegroundColor $highColor
Write-Host ("  MEDIUM risk: {0}" -f $mediumCount) -ForegroundColor $medColor
Write-Host ("  Planned: {0}" -f $plannedChanges.Count) -ForegroundColor Gray
$appColor = if ($appliedChanges.Count -gt 0) { "Green" } else { "Gray" }
Write-Host ("  Applied: {0}" -f $appliedChanges.Count) -ForegroundColor $appColor
$failColor = if ($failedChanges.Count -gt 0) { "Red" } else { "Gray" }
Write-Host ("  Failed: {0}" -f $failedChanges.Count) -ForegroundColor $failColor

$result = @{
    highRiskSlots   = $highRiskSlots
    mediumRiskSlots = $mediumRiskSlots
    plannedChanges  = $plannedChanges
    appliedChanges  = $appliedChanges
    failedChanges   = $failedChanges
}
$result | ConvertTo-Json -Depth 5
