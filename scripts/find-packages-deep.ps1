$ErrorActionPreference = 'SilentlyContinue'
Write-Host "=== AppData\Local\Packages - Full Scan ==="
$pkg = "C:\Users\Administrator\AppData\Local\Packages"
$folders = Get-ChildItem $pkg -Directory -Force -ErrorAction SilentlyContinue
$results = @()
foreach ($f in $folders) {
    $size = 0
    $files = Get-ChildItem $f.FullName -Recurse -Force -ErrorAction SilentlyContinue
    foreach ($file in $files) { $size += $file.Length }
    $results += [PSCustomObject]@{Name=$f.Name; SizeGB=[math]::Round($size/1GB,2); FileCount=$files.Count}
}
$results | Sort-Object SizeGB -Descending | Select-Object -First 15 | Format-Table -AutoSize
Write-Host ""
Write-Host "Total packages: $($folders.Count), Total size: $([math]::Round(($results | Measure -Property SizeGB -Sum).Sum,2)) GB"
