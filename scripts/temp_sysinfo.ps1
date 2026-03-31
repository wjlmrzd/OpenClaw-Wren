$os = Get-CimInstance Win32_OperatingSystem
$totalMem = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
$freeMem = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
$usedMem = [math]::Round($totalMem - $freeMem, 1)
$memPct = [math]::Round(($usedMem / $totalMem) * 100, 1)
Write-Output "MemTotal=$totalMem"
Write-Output "MemUsed=$usedMem"
Write-Output "MemPct=$memPct"

$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
foreach ($d in $disks) {
    $total = [math]::Round($d.Size / 1GB, 1)
    $free = [math]::Round($d.FreeSpace / 1GB, 1)
    $pct = [math]::Round((($total - $free) / $total) * 100, 1)
    Write-Output "Disk$($d.DeviceID) Total=$total UsedGB=$([math]::Round($total - $free, 1)) Pct=$pct"
}
