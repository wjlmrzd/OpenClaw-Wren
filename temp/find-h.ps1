[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$out = @()

# Check OneDrive
$out += "=== H:\OneDrive ==="
if (Test-Path "H:\OneDrive") {
    Get-ChildItem "H:\OneDrive" -Directory -ErrorAction SilentlyContinue | Select-Object -First 20 | ForEach-Object { $out += $_.Name }
}

# Check Baidu Netdisk
$out += ""
$out += "=== H:\百度网盘 ==="
if (Test-Path "H:\百度网盘") {
    Get-ChildItem "H:\百度网盘" -Directory -ErrorAction SilentlyContinue | Select-Object -First 20 | ForEach-Object { $out += $_.Name }
}

# Check 天翼云盘
$out += ""
$out += "=== H:\天翼云盘 ==="
if (Test-Path "H:\天翼云盘") {
    Get-ChildItem "H:\天翼云盘" -Directory -ErrorAction SilentlyContinue | Select-Object -First 20 | ForEach-Object { $out += $_.Name }
}

# Check 阿里云盘
$out += ""
$out += "=== H:\阿里云盘Open ==="
if (Test-Path "H:\阿里云盘Open") {
    Get-ChildItem "H:\阿里云盘Open" -Directory -ErrorAction SilentlyContinue | Select-Object -First 20 | ForEach-Object { $out += $_.Name }
}

$out | Out-File -FilePath "D:\OpenClaw\.openclaw\workspace\temp\find-h.txt" -Encoding UTF8
Write-Output "Done"
