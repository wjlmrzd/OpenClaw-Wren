$os = Get-CimInstance Win32_OperatingSystem
$usedMem = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)
$totalMem = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$memPct = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)
Write-Output "MEMORY|$usedMem|$totalMem|$memPct"

Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object {
    $used = [math]::Round(($_.Size - $_.FreeSpace) / 1GB, 1)
    $free = [math]::Round($_.FreeSpace / 1GB, 1)
    $pct = [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 1)
    Write-Output "DISK|$($_.DeviceID)|$used|$free|$pct"
}
