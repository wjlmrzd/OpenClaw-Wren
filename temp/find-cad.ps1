[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$out = @()

# Check CAD-related folders in home directory
$homeDirs = @(
    "C:\Users\Administrator\Documents\CADReader",
    "C:\Users\Administrator\Documents\DllRepair",
    "C:\Users\Administrator\Desktop"
)

foreach ($dir in $homeDirs) {
    $out += "=== $dir ==="
    if (Test-Path $dir) {
        Get-ChildItem $dir -Directory | ForEach-Object { $out += $_.Name }
        Get-ChildItem $dir -File | ForEach-Object { $out += $_.Name }
    } else {
        $out += "NOT FOUND"
    }
    $out += ""
}

# Search for "block" in file/folder names
$out += "=== Searching for 'block' or 'attribute' or '属性' ==="
$searchResults = Get-ChildItem "C:\Users\Administrator" -Directory -Recurse -Depth 3 -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*block*" -or $_.Name -like "*Block*" -or $_.Name -like "*attribute*" -or $_.Name -like "*Attribute*" }
if ($searchResults) {
    $searchResults | ForEach-Object { $out += $_.FullName }
} else {
    $out += "Not found in C:\Users\Administrator"
}

$out | Out-File -FilePath "D:\OpenClaw\.openclaw\workspace\temp\find-cad.txt" -Encoding UTF8
Write-Output "Done"
