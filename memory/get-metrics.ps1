$mem = Get-CimInstance Win32_OperatingSystem
$totalMem = [math]::Round($mem.TotalVisibleMemorySize / 1MB, 2)
$freeMem = [math]::Round($mem.FreePhysicalMemory / 1MB, 2)
$usedMemPct = [math]::Round(($totalMem - $freeMem) / $totalMem * 100, 1)
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='D:'"
$diskFree = [math]::Round($disk.FreeSpace / 1GB, 1)
Write-Output "MEMORY:${usedMemPct}%"
Write-Output "DISK_FREE:${diskFree}GB"
