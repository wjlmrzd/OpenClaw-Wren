$file1 = "D:\OpenClaw\.openclaw\workspace\memory\cron-jobs.json"
$bytes1 = [System.IO.File]::ReadAllBytes($file1)
Write-Host "cron-jobs.json: $($bytes1.Length) bytes"
Write-Host "First bytes: $(($bytes1[0..15] | ForEach-Object { '{0:X2}' -f $_ }) -join ' ')"

$file2 = "D:\OpenClaw\.openclaw\workspace\memory\cron-list.json"
$bytes2 = [System.IO.File]::ReadAllBytes($file2)
Write-Host "cron-list.json: $($bytes2.Length) bytes (CORRUPTED!)"
Write-Host "First bytes: $(($bytes2[0..15] | ForEach-Object { '{0:X2}' -f $_ }) -join ' ')"
