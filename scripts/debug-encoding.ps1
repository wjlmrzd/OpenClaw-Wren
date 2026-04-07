$file = "D:\OpenClaw\.openclaw\workspace\memory\cron-list.json"
$bytes = [System.IO.File]::ReadAllBytes($file)
Write-Host "Total bytes: $($bytes.Length)"
Write-Host "First 20 hex: $(($bytes[0..19] | ForEach-Object { '{0:X2}' -f $_ }) -join ' ')"
Write-Host "Last 20 hex: $(($bytes[-20..-1] | ForEach-Object { '{0:X2}' -f $_ }) -join ' ')"

# Try reading as UTF-8
$utf8 = New-Object System.Text.UTF8Encoding $False
$text8 = $utf8.GetString($bytes)
Write-Host "UTF-8 read: $($text8.Length) chars, first 50: $($text8.Substring(0, [Math]::Min(50, $text8.Length)))"

# Try as UTF-16 LE (Unicode)
$text16 = [System.Text.Encoding]::Unicode.GetString($bytes)
Write-Host "UTF-16 read: $($text16.Length) chars, first 50: $($text16.Substring(0, [Math]::Min(50, $text16.Length)))"

# Skip BOM and read UTF-16 LE
$text16b = [System.Text.Encoding]::Unicode.GetString($bytes, 2, $bytes.Length - 2)
Write-Host "UTF-16-BOM skipped: $($text16b.Length) chars, first 50: $($text16b.Substring(0, [Math]::Min(50, $text16b.Length)))"
