$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== AppData Sizes ==="
$appDataPath = "$env:USERPROFILE\AppData"
$folders = @("Local","LocalLow","Roaming")
foreach ($f in $folders) {
    $path = Join-Path $appDataPath $f
    if (Test-Path $path) {
        Write-Host "Scanning AppData\$f..."
        $items = Get-ChildItem $path -Directory -Force -ErrorAction SilentlyContinue
        $totalSize = 0
        $results = @()
        foreach ($item in $items) {
            $files = Get-ChildItem $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
            $size = 0
            foreach ($file in $files) { $size += $file.Length }
            $results += [PSCustomObject]@{Folder=$item.Name; SizeGB=[math]::Round($size/1GB,2)}
            $totalSize += $size
        }
        $results | Sort-Object SizeGB -Descending | Select-Object -First 10 | Format-Table -AutoSize
        Write-Host "Subtotal: $([math]::Round($totalSize/1GB,2)) GB"
        Write-Host ""
    }
}

Write-Host "=== Leidian Emulator ==="
$ld = "C:\leidian"
if (Test-Path $ld) {
    Write-Host "Scanning Leidian..."
    $items = Get-ChildItem $ld -Directory -Force -ErrorAction SilentlyContinue
    foreach ($item in $items) {
        $files = Get-ChildItem $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
        $size = 0
        foreach ($f in $files) { $size += $f.Length }
        Write-Host "  $($item.Name): $([math]::Round($size/1GB,2)) GB"
    }
} else {
    Write-Host "  Not found"
}

Write-Host ""
Write-Host "=== Downloads Top 20 ==="
$dl = "$env:USERPROFILE\Downloads"
if (Test-Path $dl) {
    $files = Get-ChildItem $dl -File -Force -ErrorAction SilentlyContinue | Sort-Object Length -Descending | Select-Object -First 20
    $total = 0
    foreach ($f in $files) { $total += $f.Length }
    foreach ($f in $files) {
        $sizeGB = [math]::Round($f.Length/1GB,3)
        if ($sizeGB -gt 0) {
            Write-Host "  $sizeGB GB - $($f.Name)"
        } else {
            $sizeMB = [math]::Round($f.Length/1MB,1)
            Write-Host "  $sizeMB MB - $($f.Name)"
        }
    }
    Write-Host "  Top 20 total: $([math]::Round($total/1GB,2)) GB"
    $allDl = Get-ChildItem $dl -File -Force -ErrorAction SilentlyContinue
    $allSize = 0
    foreach ($f in $allDl) { $allSize += $f.Length }
    Write-Host "  Downloads total: $([math]::Round($allSize/1GB,2)) GB ($($allDl.Count) files)"
}
