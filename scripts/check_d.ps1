$d = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='D:'"
$pct = [math]::Round(($d.Size - $d.FreeSpace) / $d.Size * 100, 1)
Write-Output "D_drive_used=$($pct)%"
Write-Output "D_drive_free=$( [math]::Round($d.FreeSpace/1GB, 1) )GB"
