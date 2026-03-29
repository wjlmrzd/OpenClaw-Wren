[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$out = @()

# Check specific paths
$paths = @(
    "D:\my project",
    "D:\my_project",
    "D:\MyProject",
    "D:\My Project",
    "C:\my project",
    "C:\my_project",
    "C:\MyProject",
    "C:\Users\Administrator\my project",
    "C:\Users\Administrator\My Projects",
    "H:\OneDrive\文档",
    "H:\OneDrive\文档\my project",
    "H:\Personal Vault"
)

foreach ($p in $paths) {
    $exists = Test-Path $p
    $out += "$exists : $p"
}

# Check the LISP folder more carefully
$out += ""
$out += "=== D:\LISP学习资料精选 contents ==="
if (Test-Path "D:\LISP学习资料精选") {
    Get-ChildItem "D:\LISP学习资料精选" -Directory | ForEach-Object { $out += "DIR: $($_.Name)" }
    Get-ChildItem "D:\LISP学习资料精选" -File | ForEach-Object { $out += "FILE: $($_.Name)" }
}

# Check 百度网盘
$out += ""
$out += "=== D:\BaiduNetdiskDownload contents ==="
if (Test-Path "D:\BaiduNetdiskDownload") {
    Get-ChildItem "D:\BaiduNetdiskDownload" -Directory | ForEach-Object { $out += "DIR: $($_.Name)" }
}

# Check H:\OneDrive\文档
$out += ""
$out += "=== H:\OneDrive\文档 contents ==="
if (Test-Path "H:\OneDrive\文档") {
    Get-ChildItem "H:\OneDrive\文档" -Directory | ForEach-Object { $out += "DIR: $($_.Name)" }
    Get-ChildItem "H:\OneDrive\文档" -File | ForEach-Object { $out += "FILE: $($_.Name)" }
}

$out | Out-File -FilePath "D:\OpenClaw\.openclaw\workspace\temp\check-paths.txt" -Encoding UTF8
Write-Output "Done"
