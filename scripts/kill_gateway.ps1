$ErrorActionPreference = 'SilentlyContinue'
Stop-Process -Id 25832 -Force
Start-Sleep 3
Get-Process node | Select-Object Id, @{N='MemMB';E={[math]::Round($_.WorkingSet/1MB,1)}}, StartTime | Format-Table -AutoSize
