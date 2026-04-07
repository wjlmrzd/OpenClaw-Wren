$ErrorActionPreference = 'SilentlyContinue'
Stop-Process -Id 25832 -Force
Start-Sleep 3
Write-Output "After kill:"
Get-Process node | Select-Object Id, @{N='MemMB';E={[math]::Round($_.WorkingSet/1MB,1)}}, StartTime | Format-Table -AutoSize
Write-Output "---"
Get-NetTCPConnection -LocalPort 18789 -ErrorAction SilentlyContinue | Select-Object OwningProcess, LocalPort, State | Format-Table -AutoSize
