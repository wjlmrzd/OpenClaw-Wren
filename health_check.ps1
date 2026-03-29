$os = Get-CimInstance Win32_OperatingSystem
$totalMB = [math]::Round($os.TotalVisibleMemorySize/1KB, 0)
$freeMB = [math]::Round($os.FreePhysicalMemory/1KB, 0)
$usedMB = $totalMB - $freeMB
$usedPct = [math]::Round($usedMB / $totalMB * 100, 1)
$totalGB = [math]::Round($totalMB / 1024, 2)
$freeGB = [math]::Round($freeMB / 1024, 2)
Write-Host "MEMORY:${usedPct}:${freeGB}:${totalGB}"

$drive = Get-PSDrive D
$usedBytes = $drive.Used
$freeBytes = $drive.Free
$totalGB2 = [math]::Round(($usedBytes + $freeBytes) / 1GB, 1)
$freeGB2 = [math]::Round($freeBytes / 1GB, 1)
$usedPct2 = [math]::Round($usedBytes / ($usedBytes + $freeBytes) * 100, 1)
Write-Host "DISK:${usedPct2}:${freeGB2}:${totalGB2}"
