[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$out = @()

# Check the GUID directory on D:\
$out += "=== D:\3e3cb7afe9186b77757e4507497921 ==="
if (Test-Path "D:\3e3cb7afe9186b77757e4507497921") {
    Get-ChildItem "D:\3e3cb7afe9186b77757e4507497921" -Directory | ForEach-Object { $out += $_.Name }
}

# Check the hidden GUID directory
$out += ""
$out += "=== D:\4cfaf3306f4945fd95e2a03193abecf1 ==="
if (Test-Path "D:\4cfaf3306f4945fd95e2a03193abecf1") {
    Get-ChildItem "D:\4cfaf3306f4945fd95e2a03193abecf1" -Directory | ForEach-Object { $out += $_.Name }
}

# Check BaiduNetdiskDownload
$out += ""
$out += "=== D:\BaiduNetdiskDownload ==="
if (Test-Path "D:\BaiduNetdiskDownload") {
    Get-ChildItem "D:\BaiduNetdiskDownload" -Directory | Select-Object -First 20 | ForEach-Object { $out += $_.Name }
}

# Check QLDownload
$out += ""
$out += "=== D:\QLDownload ==="
if (Test-Path "D:\QLDownload") {
    Get-ChildItem "D:\QLDownload" -Directory | Select-Object -First 20 | ForEach-Object { $out += $_.Name }
}

# Check 下载
$out += ""
$out += "=== D:\下载 ==="
if (Test-Path "D:\下载") {
    Get-ChildItem "D:\下载" -Directory | Select-Object -First 20 | ForEach-Object { $out += $_.Name }
}

$out | Out-File -FilePath "D:\OpenClaw\.openclaw\workspace\temp\more-dirs.txt" -Encoding UTF8
Write-Output "Done"
