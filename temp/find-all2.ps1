[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$out = @()

# List OneDrive contents
$out += "=== H:\OneDrive contents ==="
if (Test-Path "H:\OneDrive") {
    Get-ChildItem "H:\OneDrive" -Directory -ErrorAction SilentlyContinue | ForEach-Object { 
        $out += $_.Name 
    }
}

# List 百度网盘 contents
$out += ""
$out += "=== H:\百度网盘 contents ==="
if (Test-Path "H:\百度网盘") {
    Get-ChildItem "H:\百度网盘" -Directory -ErrorAction SilentlyContinue | Select-Object -First 30 | ForEach-Object { 
        $out += $_.Name 
    }
}

# Search C:\Users\Administrator for "project"
$out += ""
$out += "=== Searching C:\Users for 'project' ==="
Get-ChildItem "C:\Users" -Directory -Recurse -Depth 3 -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*project*" -or $_.Name -like "*Project*" } | ForEach-Object {
    $out += $_.FullName
}

# Search D:\ for "转" character
$out += ""
$out += "=== Searching D:\ for Chinese '转' ==="
Get-ChildItem "D:\" -Directory -Recurse -Depth 5 -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*转*" } | ForEach-Object {
    $out += $_.FullName
}

$out | Out-File -FilePath "D:\OpenClaw\.openclaw\workspace\temp\find-all2.txt" -Encoding UTF8
Write-Output "Done"
