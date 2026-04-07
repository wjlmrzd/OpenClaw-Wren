Get-ChildItem 'D:\OpenClaw\.openclaw' -Recurse -Filter 'cron*' -File -EA SilentlyContinue | Select-Object FullName, Length, LastWriteTime | Format-Table -AutoSize
