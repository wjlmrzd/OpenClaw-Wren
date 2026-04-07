$ErrorActionPreference = 'SilentlyContinue'
$nodes = Get-Process node | Select-Object Id, @{N='MemMB';E={[math]::Round($_.WorkingSet/1MB,1)}}, StartTime
$nodes | Format-Table -AutoSize
Write-Output "---"
Get-NetTCPConnection -LocalPort 18789 | Select-Object OwningProcess, LocalAddress, LocalPort, State | Format-Table -AutoSize
