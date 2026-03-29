[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System. Text.Encoding]::UTF8

$out = @()

# Search ALL drives for LSP files with relevant content
$drives = @("C:", "D:", "E:", "H:")
$foundFiles = @()
$allLspFiles = @()

foreach ($drive in $drives) {
    try {
        $files = Get-ChildItem "$drive\" -File -Recurse -Depth 4 -Filter "*.lsp" -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            $allLspFiles += $f.FullName
            try {
                $content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
                # Check for attribute/block conversion related patterns
                if ($content -match "attribout|attrib.*out|attribute.*block|转属性|att2blk|blk2att|block2att|makeatt|entmake.*att") {
                    $foundFiles += $f.FullName
                }
            } catch {}
        }
    } catch {}
}

$out += "Total LSP files found: $($allLspFiles.Count)"
$out += ""
$out += "Files with attribute/block conversion patterns:"
if ($foundFiles.Count -gt 0) {
    foreach ($f in $foundFiles) {
        $out += "  $f"
    }
} else {
    $out += "  (none found)"
}
$out += ""
$out += "All LSP files:"
foreach ($f in $allLspFiles) {
    $out += "  $f"
}

$out | Out-File -FilePath "D:\OpenClaw\.openclaw\workspace\temp\find-convert3.txt" -Encoding UTF8
Write-Output "Done"
