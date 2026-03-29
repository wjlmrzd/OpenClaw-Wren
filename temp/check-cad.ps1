[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$out = @()
$out += "=== D:\CAD_PluginLoader ==="
if (Test-Path "D:\CAD_PluginLoader") {
    Get-ChildItem "D:\CAD_PluginLoader" -Directory | ForEach-Object { $out += $_.Name }
} else {
    $out += "NOT FOUND"
}

$out += ""
$out += "=== D:\cad-lsp-manager ==="
if (Test-Path "D:\cad-lsp-manager") {
    Get-ChildItem "D:\cad-lsp-manager" -Directory | ForEach-Object { $out += $_.Name }
} else {
    $out += "NOT FOUND"
}

# Check for any subdir with "project" or containing 块
$out += ""
$out += "=== Search for 转属性 or 块 ==="
Get-ChildItem "D:\" -Directory -Recurse -Depth 3 -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*块*" -or $_.Name -like "*转*" } | ForEach-Object { $out += $_.FullName }

$out | Out-File -FilePath "D:\OpenClaw\.openclaw\workspace\temp\cad-check.txt" -Encoding UTF8
Write-Output "Done"
