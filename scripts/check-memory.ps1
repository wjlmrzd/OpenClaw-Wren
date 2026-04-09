$os = Get-CimInstance Win32_OperatingSystem
$used = $os.TotalVisibleMemorySize - $os.FreePhysicalMemory
$percent = [math]::Round($used / $os.TotalVisibleMemorySize * 100, 1)
Write-Host "Memory: $percent%"
