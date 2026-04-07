$b = [System.IO.File]::ReadAllBytes('D:\OpenClaw\.openclaw\workspace\memory\cron-jobs.json')
$start = [Math]::Max(0, 940)
$end = [Math]::Min($b.Length, 1020)
$chunk = $b[$start..$end]
Write-Host "Bytes $start-$end ($($chunk.Count) bytes):"
$hex = ($chunk | ForEach-Object { $_.ToString('X2') }) -join ' '
Write-Host $hex
$chars = -join ($chunk | ForEach-Object { if ($_ -ge 32 -and $_ -le 126) { [char]$_ } else { '.' } })
Write-Host $chars
