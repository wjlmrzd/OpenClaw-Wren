$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=== LARGEST FILES IN D:\OpenClaw ==="
Get-ChildItem "D:\OpenClaw" -Recurse -File -ErrorAction SilentlyContinue |
    Sort-Object Length -Descending |
    Select-Object -First 20 FullName, Length |
    ForEach-Object {
        $mb = [math]::Round($_.Length / 1MB, 1)
        Write-Host "$mb MB - $($_.FullName)"
    }

Write-Host ""
Write-Host "=== WINDOWS TEMP SIZE ==="
$wtemp = Get-ChildItem "C:\Windows\Temp" -Recurse -ErrorAction SilentlyContinue
$wtempCount = $wtemp.Count
$wtempSize = [math]::Round(($wtemp | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
Write-Host "Count: $wtempCount | Size: $wtempSize MB"

Write-Host ""
Write-Host "=== OPENCLAW LOGS SIZE ==="
$logs = Get-ChildItem "D:\OpenClaw\.openclaw\logs" -Recurse -ErrorAction SilentlyContinue
$logsCount = $logs.Count
$logsSize = [math]::Round(($logs | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
Write-Host "Count: $logsCount | Size: $logsSize MB"

Write-Host ""
Write-Host "=== NODE MODULES SIZE ==="
$nm = Get-ChildItem "D:\OpenClaw\.openclaw\node_modules" -Recurse -ErrorAction SilentlyContinue
$nmCount = $nm.Count
$nmSize = [math]::Round(($nm | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
Write-Host "Count: $nmCount | Size: $nmSize MB"

Write-Host "done"
