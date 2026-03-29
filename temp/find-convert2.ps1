[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$out = @()

# Search ALL LSP files in D:\ for patterns
$out += "=== Searching ALL LSP files in D:\ ==="
$lspFiles = @()
Get-ChildItem "D:\" -File -Recurse -Depth 4 -Filter "*.lsp" -ErrorAction SilentlyContinue | ForEach-Object {
    $lspFiles += $_.FullName
}

$out += "Found $($lspFiles.Count) LSP files"

# Read each file and check for "转" or "属性" 
$found = @()
foreach ($f in $lspFiles) {
    try {
        $content = Get-Content $f -Raw -ErrorAction SilentlyContinue
        if ($content -match "转属性|attribout|blockAttribute|attributeBlock|convert.*block|block.*convert") {
            $found += $f
        }
    } catch {}
}

if ($found.Count -gt 0) {
    $out += "Files with relevant patterns:"
    foreach ($f in $found) {
        $out += "  $f"
    }
} else {
    $out += "No files found with conversion/attribute patterns"
}

# Also list all LSP files found
$out += ""
$out += "All LSP files in D:\"
foreach ($f in $lspFiles) {
    $out += "  $f"
}

$out | Out-File -FilePath "D:\OpenClaw\.openclaw\workspace\temp\find-convert2.txt" -Encoding UTF8
Write-Output "Done"
