[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$out = @()

# Search all of D:\OpenClaw for Chinese characters or specific patterns
$out += "=== D:\OpenClaw - All directories ==="
Get-ChildItem "D:\OpenClaw" -Directory -Recurse -Depth 5 -ErrorAction SilentlyContinue | Where-Object { 
    $_.Name.Length -gt 0
} | Select-Object FullName | ForEach-Object {
    $out += $_.FullName
}

# Also search for any .lsp file containing "att" (attribute) or "blk" (block)
$out += ""
$out += "=== D:\OpenClaw - LSP files with 'att' or 'blk' in name ==="
Get-ChildItem "D:\OpenClaw" -File -Recurse -Filter "*.lsp" -Depth 5 -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -like "*att*" -or $_.Name -like "*Att*" -or $_.Name -like "*blk*" -or $_.Name -like "*Blk*" -or $_.Name -like "*block*" -or $_.Name -like "*Block*"
} | Select-Object FullName | ForEach-Object {
    $out += $_.FullName
}

$out | Out-File -FilePath "D:\OpenClaw\.openclaw\workspace\temp\search-oc-plugins.txt" -Encoding UTF8
Write-Output "Done"
