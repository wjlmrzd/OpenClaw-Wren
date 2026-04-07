# Auto Memory Archiver
# Archives old daily logs + trims large state files
# Schedule: Daily at 04:00
param(
    [int]$RetentionDays = 7,
    [switch]$DryRun
)

$ErrorActionPreference = "SilentlyContinue"
$memDir = "D:\OpenClaw\.openclaw\workspace\memory"
$archiveDir = "$memDir\archive"
$dateStr = (Get-Date).ToString("yyyy-MM-dd")
$log = @()

function Write-Log($msg) {
    $ts = Get-Date -Format "HH:mm:ss"
    $entry = "[$ts] $msg"
    Write-Host $entry
    $script:log += $entry
}

Write-Log "=== Memory Archiver Started ==="

# 1. Archive old daily logs (but keep MEMORY.md)
$cutoffDate = (Get-Date).AddDays(-$RetentionDays)
$dailyLogs = Get-ChildItem "$memDir\*.md" | Where-Object {
    $_.Name -match "^\d{4}-\d{2}-\d{2}" -and $_.LastWriteTime -lt $cutoffDate
}

if ($dailyLogs.Count -eq 0) {
    Write-Log "No daily logs older than $RetentionDays days"
} else {
    foreach ($f in $dailyLogs) {
        $dest = "$archiveDir\$($f.Name)"
        if (-not $DryRun) {
            Move-Item $f.FullName $dest -Force
        }
        Write-Log "ARCHIVED: $($f.Name) → archive/"
    }
}

# 2. Archive old auto-healer reports
$ahReports = Get-ChildItem "$memDir\auto-healer-report-*.md" | Where-Object {
    $_.LastWriteTime -lt $cutoffDate
}
foreach ($f in $ahReports) {
    $dest = "$archiveDir\$($f.Name)"
    if (-not $DryRun) { Move-Item $f.FullName $dest -Force }
    Write-Log "ARCHIVED: $($f.Name) → archive/"
}

# 3. Archive old config audits
$cfgReports = Get-ChildItem "$memDir\config-audit-report-*.md" | Where-Object {
    $_.LastWriteTime -lt $cutoffDate -and $_.Name -ne "config-audit-report.md"
}
foreach ($f in $cfgReports) {
    $dest = "$archiveDir\$($f.Name)"
    if (-not $DryRun) { Move-Item $f.FullName $dest -Force }
    Write-Log "ARCHIVED: $($f.Name) → archive/"
}

# 4. Trim cron-jobs.json (keep last 30 entries)
$cjPath = "$memDir\cron-jobs.json"
if (Test-Path $cjPath) {
    $cj = Get-Content $cjPath -Raw | ConvertFrom-Json
    if ($cj.jobs -and $cj.jobs.Count -gt 30) {
        $oldCount = $cj.jobs.Count
        $cj.jobs = $cj.jobs | Select-Object -Last 30
        if (-not $DryRun) {
            $cj | ConvertTo-Json -Depth 5 | Set-Content $cjPath -Encoding UTF8
        }
        Write-Log "TRIMMED: cron-jobs.json $oldCount → $($cj.jobs.Count) entries"
    }
}

# 5. Archive large test-git.json
$tgPath = "$memDir\test-git.json"
if (Test-Path $tgPath) {
    $sizeMB = [math]::Round($(Get-Item $tgPath).Length / 1MB, 1)
    if ($sizeMB -gt 5) {
        $dest = "$archiveDir\test-git-archived-$dateStr.json"
        if (-not $DryRun) { Move-Item $tgPath $dest }
        Write-Log "ARCHIVED: test-git.json ($sizeMB MB) → archive/"
    }
}

# 6. Reset test-runner-state.json (only keep recent runs)
$trsPath = "$memDir\test-runner-state.json"
if (Test-Path $trsPath) {
    $trs = Get-Content $trsPath -Raw | ConvertFrom-Json
    if ($trs.runs -and $trs.runs.Count -gt 50) {
        $trs.runs = $trs.runs | Select-Object -Last 50
        if (-not $DryRun) {
            $trs | ConvertTo-Json -Depth 5 | Set-Content $trsPath -Encoding UTF8
        }
        Write-Log "TRIMMED: test-runner-state.json (kept last 50 runs)"
    }
}

# 7. Archive empty/large auto-healer-log.md
$ahlPath = "$memDir\auto-healer-log.md"
if (Test-Path $ahlPath) {
    $ahl = Get-Content $ahlPath -Raw
    if ($ahl.Length -gt 5000) {
        $dest = "$archiveDir\auto-healer-log-archived-$dateStr.md"
        if (-not $DryRun) {
            Move-Item $ahlPath $dest
            "# Auto-healer log archived $dateStr" | Set-Content $ahlPath -Encoding UTF8
        }
        Write-Log "ARCHIVED: auto-healer-log.md → archive/"
    }
}

# 8. Archive old .memory-index.json backups
$miFiles = Get-ChildItem "$memDir\.memory-index*.json"
foreach ($f in $miFiles) {
    $dest = "$archiveDir\$($f.Name)"
    if (-not $DryRun) { Move-Item $f.FullName $dest -Force }
    Write-Log "ARCHIVED: $($f.Name) → archive/"
}

# 9. Summary
$archivedCount = $dailyLogs.Count + $ahReports.Count + $cfgReports.Count + $(if (Test-Path $tgPath) { 0 } else { 0 })
$summary = "=== Archiver Complete ===`nArchived: $($script:log.Count - 1) items`nFiles in archive: $((Get-ChildItem $archiveDir).Count)"
Write-Log $summary

# Save log
$logFile = "$memDir\archiver-log.md"
$logContent = @"
# Memory Archiver Log — $dateStr

$($script:log | Out-String)

---
*DryRun: $DryRun | Retention: $RetentionDays days*
"@
if (-not $DryRun) {
    Add-Content -Path $logFile -Value $logContent -Encoding UTF8
}

Write-Host $summary
