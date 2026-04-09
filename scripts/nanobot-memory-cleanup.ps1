# nanobot-style memory cleanup
param(
    [int]$ArchiveDays = 7,
    [switch]$DryRun
)

$memoryDir = "D:\OpenClaw\.openclaw\workspace\memory"
$archiveDir = "$memoryDir\archive"

if (!(Test-Path $archiveDir)) {
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
}

$today = Get-Date
$cutoffDate = $today.AddDays(-$ArchiveDays)

# === 1. 归档旧 daily logs (7天前) ===
$dailyLogs = Get-ChildItem -Path $memoryDir -Filter "2026-*.md" | Where-Object {
    $_.Name -match "^\d{4}-\d{2}-\d{2}" -and $_.LastWriteTime -lt $cutoffDate
}

$archived = 0
foreach ($log in $dailyLogs) {
    $dest = Join-Path $archiveDir $log.Name
    if (!$DryRun) {
        Move-Item -Path $log.FullName -Destination $dest -Force
    }
    $archived++
    Write-Host "  ARCHIVE: $($log.Name)"
}

# === 2. 归档旧大 state JSON (>50KB, 7天前未修改) ===
$skipNames = @("cron-jobs.json", "sessions.json")
$stateFiles = Get-ChildItem -Path $memoryDir -Filter "*.json" | Where-Object {
    $f = $_
    $skipNames -notcontains $f.Name -and
    $f.Length -gt 51200 -and
    $f.LastWriteTime -lt $cutoffDate
}

$archivedState = 0
foreach ($f in $stateFiles) {
    $dest = Join-Path $archiveDir $f.Name
    if (!$DryRun) {
        Move-Item -Path $f.FullName -Destination $dest -Force
    }
    $archivedState++
    Write-Host "  ARCHIVE_STATE: $($f.Name)"
}

# === 3. 归档旧报告 (>14天) ===
$oldReports = Get-ChildItem -Path $memoryDir -Filter "*report*.md" | Where-Object {
    $_.LastWriteTime -lt $today.AddDays(-14)
}
$archivedReports = 0
foreach ($r in $oldReports) {
    $dest = Join-Path $archiveDir $r.Name
    if (!$DryRun) {
        Move-Item -Path $r.FullName -Destination $dest -Force
    }
    $archivedReports++
    Write-Host "  ARCHIVE_REPORT: $($r.Name)"
}

# === 4. 统计 ===
$remaining = (Get-ChildItem -Path $memoryDir -File | Measure-Object).Count

Write-Host ""
Write-Host "=== Memory Cleanup Summary ==="
Write-Host "  Archived daily logs: $archived"
Write-Host "  Archived state files: $archivedState"
Write-Host "  Archived reports: $archivedReports"
Write-Host "  Remaining in memory/: $remaining"

if ($DryRun) {
    Write-Host "[DRY RUN - no files moved]"
}
