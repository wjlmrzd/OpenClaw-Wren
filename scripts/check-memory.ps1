$os = Get-CimInstance Win32_OperatingSystem
$total = $os.TotalVisibleMemorySize / 1MB
$free = $os.FreePhysicalMemory / 1MB
$used = $total - $free
$percent = [math]::Round($used / $total * 100, 1)
Write-Output $percent
