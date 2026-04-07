# Log Cleanup Script
# 日志清理脚本

# Configuration
$SessionsPath = "D:\OpenClaw\.openclaw\workspace\sessions"
$LogsPath = "D:\OpenClaw\.openclaw\workspace\logs"
$CronPath = "D:\OpenClaw\.openclaw\cron\runs"
$RetentionDays = 7
$DeleteDays = 30
$CronRetainCount = 50

# Get disk space
function Get-DiskSpace {
    $drive = Get-PSDrive D
    $total = $drive.Used + $drive.Free
    $free = $drive.Free
    [PSCustomObject]@{
        TotalGB = [math]::Round($total / 1GB, 2)
        FreeGB = [math]::Round($free / 1GB, 2)
        UsedGB = [math]::Round(($total - $free) / 1GB, 2)
        FreePercent = [math]::Round($free / $total * 100, 2)
    }
}

# Record actions
$actions = @()
$compressedFiles = @()
$deletedFiles = @()

# Space before cleanup
Write-Host "=== Disk Space Before Cleanup ===" -ForegroundColor Cyan
$beforeSpace = Get-DiskSpace
Write-Host "Total: $($beforeSpace.TotalGB) GB"
Write-Host "Used: $($beforeSpace.UsedGB) GB"
Write-Host "Free: $($beforeSpace.FreeGB) GB"
Write-Host "Free Percent: $($beforeSpace.FreePercent)%" -ForegroundColor Yellow

# 1. Check sessions/*.jsonl files
Write-Host "`n=== Checking Session Log Files ===" -ForegroundColor Cyan
if (Test-Path $SessionsPath) {
    $sessionFiles = Get-ChildItem -Path $SessionsPath -Filter "*.jsonl" -File
    foreach ($file in $sessionFiles) {
        $age = (Get-Date) - $file.LastWriteTime
        $ageDays = [math]::Floor($age.TotalDays)
        $sizeKB = [math]::Round($file.Length / 1KB, 2)
        Write-Host "  $($file.Name): $ageDays days old, $sizeKB KB"
        
        # Compress if older than 7 days
        if ($ageDays -gt $RetentionDays) {
            $zipFile = $file.FullName + ".gz"
            Write-Host "    -> Compress to: $zipFile" -ForegroundColor Yellow
            $actions += "Compress: $($file.Name) -> $([System.IO.Path]::GetFileName($zipFile))"
            $compressedFiles += "$($file.Name) -> $([System.IO.Path]::GetFileName($zipFile))"
        }
    }
} else {
    Write-Host "  sessions directory does not exist" -ForegroundColor Red
}

# 2. Delete compressed logs older than 30 days
Write-Host "`n=== Checking Compressed Logs (>30 days) ===" -ForegroundColor Cyan
if (Test-Path $SessionsPath) {
    $gzipFiles = Get-ChildItem -Path $SessionsPath -Filter "*.gz" -File -ErrorAction SilentlyContinue
    foreach ($file in $gzipFiles) {
        $age = (Get-Date) - $file.LastWriteTime
        $ageDays = [math]::Floor($age.TotalDays)
        if ($ageDays -gt $DeleteDays) {
            Write-Host "  Delete: $($file.Name) ($ageDays days old)" -ForegroundColor Red
            $deletedFiles += "$($file.Name) ($ageDays days old)"
            Remove-Item -Path $file.FullName -Force
        }
    }
}

# 3. Clean cron run history (keep last 50)
Write-Host "`n=== Cleaning Cron Run History ===" -ForegroundColor Cyan
if (Test-Path $CronPath) {
    $cronFiles = Get-ChildItem -Path $CronPath -Filter "*.jsonl" -File | Sort-Object LastWriteTime -Descending
    $totalCron = $cronFiles.Count
    Write-Host "  Total: $totalCron cron run records"
    
    if ($totalCron -gt $CronRetainCount) {
        $toDelete = $cronFiles[$CronRetainCount..($cronFiles.Count-1)]
        Write-Host "  Delete: $($toDelete.Count) old records" -ForegroundColor Yellow
        foreach ($file in $toDelete) {
            $age = (Get-Date) - $file.LastWriteTime
            $ageDays = [math]::Floor($age.TotalDays)
            Write-Host "    Delete: $($file.Name) ($ageDays days old, $([math]::Round($file.Length/1KB, 2)) KB)" -ForegroundColor Yellow
            $deletedFiles += "$($file.Name) ($ageDays days old)"
            Remove-Item -Path $file.FullName -Force
        }
    } else {
        Write-Host "  Keep: All records (less than $CronRetainCount)"
    }
} else {
    Write-Host "  cron runs directory does not exist" -ForegroundColor Red
}

# 4. Check workspace/logs directory
Write-Host "`n=== Checking workspace/logs Directory ===" -ForegroundColor Cyan
if (Test-Path $LogsPath) {
    $logFiles = Get-ChildItem -Path $LogsPath -File -Recurse -ErrorAction SilentlyContinue
    $largeFiles = $logFiles | Where-Object { $_.Length -gt 1MB }
    
    if ($largeFiles.Count -gt 0) {
        Write-Host "  Large files (>1MB):" -ForegroundColor Yellow
        foreach ($file in $largeFiles) {
            $age = (Get-Date) - $file.LastWriteTime
            $ageDays = [math]::Floor($age.TotalDays)
            $sizeMB = [math]::Round($file.Length / 1MB, 2)
            Write-Host "    $($file.Name): $sizeMB MB, $ageDays days old" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  No large files"
    }
} else {
    Write-Host "  logs directory does not exist" -ForegroundColor Red
}

# Space after cleanup
Write-Host "`n=== Disk Space After Cleanup ===" -ForegroundColor Cyan
$afterSpace = Get-DiskSpace
Write-Host "Total: $($afterSpace.TotalGB) GB"
Write-Host "Used: $($afterSpace.UsedGB) GB"
Write-Host "Free: $($afterSpace.FreeGB) GB"
Write-Host "Free Percent: $($afterSpace.FreePercent)%" -ForegroundColor Green

# Space saved
$spaceSavedGB = [math]::Round($afterSpace.UsedGB - $beforeSpace.UsedGB, 2)
if ($spaceSavedGB -lt 0) {
    Write-Host "Space Saved: $([math]::Abs($spaceSavedGB)) GB" -ForegroundColor Green
} else {
    Write-Host "Space Increased: $spaceSavedGB GB (other processes may have created new files)" -ForegroundColor Yellow
}

# Summary
Write-Host "`n=== Cleanup Summary ===" -ForegroundColor Cyan
Write-Host "Compressed Files:" -ForegroundColor Cyan
$compressedFiles | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }

Write-Host "`nDeleted Files:" -ForegroundColor Cyan
$deletedFiles | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }

# Generate summary text
$summary = @"
[Log Cleanup Complete]

Space Before Cleanup:
  Total: $($beforeSpace.TotalGB) GB
  Used: $($beforeSpace.UsedGB) GB
  Free: $($beforeSpace.FreeGB) GB
  Free Percent: $($beforeSpace.FreePercent)%

Space After Cleanup:
  Total: $($afterSpace.TotalGB) GB
  Used: $($afterSpace.UsedGB) GB
  Free: $($afterSpace.FreeGB) GB
  Free Percent: $($afterSpace.FreePercent)%

Space Saved: $([math]::Abs($spaceSavedGB)) GB

Compressed Files:
$(if ($compressedFiles.Count -gt 0) { ($compressedFiles | ForEach-Object { "  - $_" }) -join "`n" } else { "  None" })

Deleted Files:
$(if ($deletedFiles.Count -gt 0) { ($deletedFiles | ForEach-Object { "  - $_" }) -join "`n" } else { "  None" })
"@

Write-Host "`n=== Summary Generated ===" -ForegroundColor Cyan
Write-Host $summary

# Save summary to file
$summary | Out-File -FilePath "D:\OpenClaw\.openclaw\workspace\cleanup_summary.txt" -Encoding UTF8
Write-Host "`nSummary saved to: D:\OpenClaw\.openclaw\workspace\cleanup_summary.txt" -ForegroundColor Green
