[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$out = @()

# Search for convert/attribute/block in D:\OpenClaw
$out += "=== D:\OpenClaw for convert/attribute/block ==="
Get-ChildItem "D:\OpenClaw" -Directory -Recurse -Depth 3 -ErrorAction SilentlyContinue | Where-Object { 
    $_.Name -like "*convert*" -or $_.Name -like "*attribute*" -or $_.Name -like "*block*" -or $_.Name -like "*Convert*" -or $_.Name -like "*Attribute*" -or $_.Name -like "*Block*"
} | ForEach-Object {
    $out += $_.FullName
}

# Also search in Desktop and Documents
$out += ""
$out += "=== Desktop/Documents for convert/attribute/block ==="
$searchPaths = @("C:\Users\Administrator\Desktop", "C:\Users\Administrator\Documents")
foreach ($path in $searchPaths) {
    if (Test-Path $path) {
        Get-ChildItem $path -Directory -Recurse -Depth 3 -ErrorAction SilentlyContinue | Where-Object { 
            $_.Name -like "*convert*" -or $_.Name -like "*attribute*" -or $_.Name -like "*block*" -or $_.Name -like "*Convert*" -or $_.Name -like "*Attribute*" -or $_.Name -like "*Block*"
        } | ForEach-Object {
            $out += $_.FullName
        }
    }
}

# Also check E:\ for any related folders
$out += ""
$out += "=== E:\ for convert/attribute/block ==="
Get-ChildItem "E:\" -Directory -Recurse -Depth 3 -ErrorAction SilentlyContinue | Where-Object { 
    $_.Name -like "*convert*" -or $_.Name -like "*attribute*" -or $_.Name -like "*block*" -or $_.Name -like "*cad*" -or $_.Name -like "*lisp*"
} | ForEach-Object {
    $out += $_.FullName
}

$out | Out-File -FilePath "D:\OpenClaw\.openclaw\workspace\temp\find-convert.txt" -Encoding UTF8
Write-Output "Done"
