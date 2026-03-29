$ErrorActionPreference = 'SilentlyContinue'
Write-Host "=== Leidian Check ==="
if (Test-Path "C:\leidian") {
    $items = Get-ChildItem "C:\leidian" -Directory -Force -ErrorAction SilentlyContinue
    foreach ($i in $items) {
        $size = 0
        $files = Get-ChildItem $i.FullName -Recurse -Force -ErrorAction SilentlyContinue
        foreach ($f in $files) { $size += $f.Length }
        Write-Host "$($i.Name): $([math]::Round($size/1GB,2)) GB"
    }
} else {
    Write-Host "C:\leidian not found"
}

Write-Host ""
Write-Host "=== Packages (Top 10) ==="
$pkg = "C:\Users\Administrator\AppData\Local\Packages"
$items = Get-ChildItem $pkg -Directory -Force -ErrorAction SilentlyContinue
$results = @()
foreach ($i in $items) {
    $size = 0
    $files = Get-ChildItem $i.FullName -Recurse -Force -ErrorAction SilentlyContinue -Depth 0
    if ($files) {
        foreach ($f in $files) { $size += $f.Length }
    }
    if ($size -gt 100MB) {
        $results += [PSCustomObject]@{Name=$i.Name; SizeGB=[math]::Round($size/1GB,2)}
    }
}
$results | Sort-Object SizeGB -Descending | Select-Object -First 10 | Format-Table -AutoSize
