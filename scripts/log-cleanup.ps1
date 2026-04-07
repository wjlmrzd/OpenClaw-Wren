# Log Cleanup Script - Batch processing to avoid timeout
# UTF-8 with BOM

param(
    [string]$OutputPath = "D:\OpenClaw\.openclaw\workspace\memory\log-cleanup-report.txt"
)

$ErrorActionPreference = "Continue"
$report = @()
$startTime = Get-Date
$initialFreeSpace = (Get-Volume -DriveLetter D).SizeRemaining / 1GB

$report += "========================================"
$report += "Log Cleanup Report"
$report += "========================================"
$report += "Execution Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$report += "Initial Free Space: $([math]::Round($initialFreeSpace, 2)) GB"
$report += ""

# ========================================
# Batch 1 - Session Log Scan
# ========================================
$report += "--- Batch 1: Session Log Scan ---"
$sessionDir = "D:\OpenClaw\.openclaw\agents\main\sessions"
$cutoffDate = (Get-Date).AddDays(-7)

$oldLogCount = 0
$oldLogSize = 0
$oldLogs = @()

if (Test-Path $sessionDir) {
    $oldLogs = Get-ChildItem $sessionDir -Filter "*.jsonl" -ErrorAction SilentlyContinue | 
               Where-Object { $_.LastWriteTime -lt $cutoffDate }
    $oldLogCount = $oldLogs.Count
    $oldLogSize = ($oldLogs | Measure-Object -Property Length -Sum).Sum / 1MB
    $report += "Found $oldLogCount log files older than 7 days"
    $report += "Total size: $([math]::Round($oldLogSize, 2)) MB"
    
    if ($oldLogCount -gt 0) {
        $report += "File list:"
        foreach ($log in $oldLogs | Select-Object -First 10) {
            $report += "  - $($log.Name) ($(Get-Date $log.LastWriteTime -Format 'yyyy-MM-dd'))"
        }
        if ($oldLogCount -gt 10) {
            $report += "  ... and $($oldLogCount - 10) more files"
        }
    }
} else {
    $report += "Session directory not found: $sessionDir"
}
$report += ""

# ========================================
# Batch 2 - Compress Old Logs
# ========================================
$report += "--- Batch 2: Compression ---"
$archiveDir = "D:\OpenClaw\.openclaw\workspace\memory\archived-logs"
if (!(Test-Path $archiveDir)) {
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
}

$compressedCount = 0
$deletedCount = 0

if ($oldLogCount -gt 0) {
    $batchSize = 20
    $batchNum = 1
    
    for ($i = 0; $i -lt $oldLogCount; $i += $batchSize) {
        $batch = $oldLogs | Select-Object -Skip $i -First $batchSize
        $batchFiles = @($batch | ForEach-Object { $_.FullName })
        
        if ($batchFiles.Count -gt 0) {
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $archiveName = "logs-batch-$batchNum-$timestamp.zip"
            $archivePath = Join-Path $archiveDir $archiveName
            
            try {
                Compress-Archive -Path $batchFiles -DestinationPath $archivePath -Force -ErrorAction Stop
                $compressedCount += $batchFiles.Count
                
                foreach ($file in $batchFiles) {
                    Remove-Item $file -Force -ErrorAction SilentlyContinue
                    $deletedCount++
                }
                
                $report += "Batch $batchNum : Compressed $($batchFiles.Count) files -> $archiveName"
            } catch {
                $report += "Batch $batchNum : Compression failed - $($_.Exception.Message)"
            }
        }
        $batchNum++
    }
} else {
    $report += "No compression needed - no old log files"
}
$report += "Total: Compressed $compressedCount files, Deleted $deletedCount original files"
$report += ""

# ========================================
# Batch 3 - Clean Old Archives (>30 days)
# ========================================
$report += "--- Batch 3: Clean Old Archives ---"
$archiveCutoff = (Get-Date).AddDays(-30)
$oldArchiveCount = 0

if (Test-Path $archiveDir) {
    $oldArchives = Get-ChildItem $archiveDir -Filter "*.zip" -ErrorAction SilentlyContinue | 
                   Where-Object { $_.LastWriteTime -lt $archiveCutoff }
    $oldArchiveCount = $oldArchives.Count
    
    foreach ($archive in $oldArchives) {
        Remove-Item $archive.FullName -Force -ErrorAction SilentlyContinue
        $report += "Deleted old archive: $($archive.Name)"
    }
    
    $report += "Deleted $oldArchiveCount archives older than 30 days"
} else {
    $report += "Archive directory not found"
}
$report += ""

# ========================================
# Batch 4 - Cron History Cleanup
# ========================================
$report += "--- Batch 4: Cron History Cleanup ---"
$cronRunsDir = "D:\OpenClaw\.openclaw\cron\runs"
$cronOldCount = 0

if (Test-Path $cronRunsDir) {
    # Get all cron run files sorted by date
    $cronRuns = Get-ChildItem $cronRunsDir -Filter "*.jsonl" -ErrorAction SilentlyContinue | 
                Sort-Object LastWriteTime -Descending
    
    $totalCronRuns = $cronRuns.Count
    $report += "Total cron run files: $totalCronRuns"
    
    if ($totalCronRuns -gt 50) {
        $toDelete = $cronRuns | Select-Object -Skip 50
        $cronOldCount = $toDelete.Count
        
        foreach ($run in $toDelete) {
            Remove-Item $run.FullName -Force -ErrorAction SilentlyContinue
        }
        
        $report += "Deleted $cronOldCount old cron run files (kept newest 50)"
    } else {
        $report += "No cleanup needed (<=50 files)"
    }
} else {
    $report += "Cron runs directory not found"
}
$report += ""

# ========================================
# Batch 5 - Disk Space Report
# ========================================
$report += "--- Batch 5: Disk Space Report ---"
$finalFreeSpace = (Get-Volume -DriveLetter D).SizeRemaining / 1GB
$freedSpace = $finalFreeSpace - $initialFreeSpace

$report += "Free space after cleanup: $([math]::Round($finalFreeSpace, 2)) GB"
$report += "Space freed: $([math]::Round($freedSpace, 2)) GB"
$report += ""

# ========================================
# Summary
# ========================================
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

$report += "========================================"
$report += "Cleanup Summary"
$report += "========================================"
$report += "Duration: $([math]::Round($duration, 2)) seconds"
$report += "Scanned log files: $oldLogCount"
$report += "Compressed: $compressedCount files"
$report += "Deleted originals: $deletedCount"
$report += "Cleaned old archives: $oldArchiveCount"
$report += "Cleaned cron runs: $cronOldCount"
$report += "Space freed: $([math]::Round($freedSpace, 2)) GB"
$report += "========================================"

# Output report
$reportText = $report -join "`n"
$reportText | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host $reportText
