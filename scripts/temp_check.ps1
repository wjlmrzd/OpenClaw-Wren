$pkg = Get-Content 'C:\Users\Administrator\AppData\Roaming\npm\node_modules\openclaw-cn\package.json' | ConvertFrom-Json
Write-Host "openclaw-cn version: $($pkg.version)"
