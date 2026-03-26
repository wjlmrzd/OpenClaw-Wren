# Log Cleanup Batch Script
# Batch processing to avoid timeout

# Batch 1: Scan old logs (older than 7 days)
Write-Host "Batch 1: Scanning old logs..."
$threshold = (Get-Date).AddDays(-7)
$oldLogs = Get-ChildItem 'D:\OpenClaw\.openclaw\workspace\memory' -Recurse -File | Where-Object { $_.LastWriteTime -lt $threshold }
Write-Host "Found $($oldLogs.Count) files older than 7 days"
$oldLogs | Format-Table FullName, LastWriteTime, Length -AutoSize

# Batch 2: Compress old logs (max 20 files at a time)
Write-Host "`nBatch 2: Compressing old logs..."
$processed = 0
foreach ($batch in ($oldLogs | Group-Object -Property { [math]::Floor($_.FullName.Length / 1GB) })) {
    if ($processed -ge 20) { break }
    $zipName = "cleanup-" + (Get-Date).ToString("yyyyMMdd-HHmmss") + ".zip"
    $batch | ForEach-Object {
        Compress-Archive -Path $_.FullName -DestinationPath "D:\OpenClaw\.openclaw\workspace\memory\$zipName" -Update
        Remove-Item $_.FullName -Force
        $processed++
    }
}
Write-Host "Compressed and removed $processed files"

# Batch 3: Remove old zip files (older than 30 days)
Write-Host "`nBatch 3: Removing old zip files..."
$zipThreshold = (Get-Date).AddDays(-30)
$oldZips = Get-ChildItem 'D:\OpenClaw\.openclaw\workspace\memory' -Filter "*.zip" -File | Where-Object { $_.LastWriteTime -lt $zipThreshold }
Write-Host "Found $($oldZips.Count) zip files older than 30 days"
$oldZips | Format-Table Name, LastWriteTime, Length -AutoSize

# Batch 4: Clean up old Cron history (keep last 50)
Write-Host "`nBatch 4: Cleaning cron history..."
$jobsPath = "D:\OpenClaw\.openclaw\workspace\memory\config-backups\jobs-*.json"
$allJobs = Get-ChildItem $jobsPath | Sort-Object LastWriteTime -Descending
$toRemove = $allJobs | Select-Object -Skip 50
Write-Host "Will remove $($toRemove.Count) old job history files"
$toRemove | Format-Table Name, LastWriteTime -AutoSize

# Batch 5: Report disk space using WMI
Write-Host "`nBatch 5: Disk space report..."
$disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='D:'"
$totalGB = [math]::Round($disk.Size / 1GB, 2)
$freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
$usedGB = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
$usagePercent = [math]::Round(($disk.Size - $disk.FreeSpace) / $disk.Size * 100, 2)
Write-Host "Disk D: ($($disk.DeviceID))"
Write-Host "  Total: $totalGB GB"
Write-Host "  Free: $freeGB GB"
Write-Host "  Used: $usedGB GB"
Write-Host "  Usage: $usagePercent%"

Write-Host "`nLog cleanup batch completed!"
