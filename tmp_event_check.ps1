$os = Get-CimInstance Win32_OperatingSystem
$totalMB = [math]::Round($os.TotalVisibleMemorySize/1MB, 1)
$freeMB = [math]::Round($os.FreePhysicalMemory/1MB, 1)
$usedMB = [math]::Round($totalMB - $freeMB, 1)
$usagePct = [math]::Round(($usedMB / $totalMB) * 100, 1)
Write-Output "Memory: used=$usedMB GB, free=$freeMB GB, total=$totalMB GB, usage=$usagePct%"

$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='D:'"
$diskFreeGB = [math]::Round($disk.FreeSpace/1GB, 1)
$diskTotalGB = [math]::Round($disk.Size/1GB, 1)
$diskUsedGB = [math]::Round($diskTotalGB - $diskFreeGB, 1)
$diskUsagePct = [math]::Round(($diskUsedGB / $diskTotalGB) * 100, 1)
Write-Output "Disk D: used=$diskUsedGB GB, free=$diskFreeGB GB, total=$diskTotalGB GB, usage=$diskUsagePct%"

$logFiles = Get-ChildItem "D:\OpenClaw\.openclaw\logs\*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 3
foreach ($f in $logFiles) {
    Write-Output "=== $($f.Name) ==="
    Get-Content $f.FullName -Tail 50 -ErrorAction SilentlyContinue | Select-String -Pattern "error|fail|timeout|exception" | Select-Object -Last 10 | ForEach-Object { $_.Line }
}
