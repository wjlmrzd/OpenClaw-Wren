[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$out = @()

$out += "=== D:\LISP学习资料精选 ==="
if (Test-Path "D:\LISP学习资料精选") {
    Get-ChildItem "D:\LISP学习资料精选" -Directory | ForEach-Object { $out += $_.Name }
    Get-ChildItem "D:\LISP学习资料精选" -File | Select-Object -First 20 | ForEach-Object { $out += $_.Name }
}

$out += ""
$out += "=== Search D:\OpenClaw\plugins for .lsp with content ==="
$lspFiles = Get-ChildItem "D:\OpenClaw\plugins" -File -Recurse -Filter "*.lsp" -Depth 5 -ErrorAction SilentlyContinue
$out += "Total LSP files: $($lspFiles.Count)"

# List all unique filenames
$uniqueNames = $lspFiles | Select-Object -ExpandProperty Name | Sort-Object -Unique
$out += "Unique filenames:"
foreach ($n in $uniqueNames) {
    $out += "  $n"
}

$out | Out-File -FilePath "D:\OpenClaw\.openclaw\workspace\temp\list-lisp.txt" -Encoding UTF8
Write-Output "Done"
