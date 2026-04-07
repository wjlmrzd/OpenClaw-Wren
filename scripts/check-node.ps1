Get-Process node -ErrorAction SilentlyContinue | Format-Table Id, ProcessName, @{N='WS(MB)';E={[math]::Round($_.WorkingSet64/1MB,1)}} -AutoSize
