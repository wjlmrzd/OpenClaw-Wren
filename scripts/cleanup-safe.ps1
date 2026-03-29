$ErrorActionPreference = 'SilentlyContinue'
Write-Host "=== Safe Cleanup Started ==="
$start = Get-Date

# 1. Clean User Temp (delete files older than 1 day)
Write-Host "[1] Cleaning User Temp (old files)..."
$tempPath = $env:TEMP
$count = 0
$size = 0
Get-ChildItem $tempPath -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
    $item = $_
    try {
        if (-not $item.PSIsContainer) {
            $size += $item.Length
            Remove-Item $item.FullName -Force -ErrorAction SilentlyContinue
            $count++
        }
    } catch {}
}
Write-Host "    Removed $count files, freed $([math]::Round($size/1GB,2)) GB"

# 2. Windows Update Cache
Write-Host "[2] Cleaning Windows Update Cache..."
$wuSize = 0
Get-ChildItem "C:\Windows\SoftwareDistribution\Download" -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
    if (-not $_.PSIsContainer) { $wuSize += $_.Length }
    Remove-Item $_.FullName -Force -Recurse -ErrorAction SilentlyContinue
}
Write-Host "    Freed $([math]::Round($wuSize/1GB,2)) GB"

# 3. Prefetch
Write-Host "[3] Cleaning Prefetch (optional - Windows rebuilds)..."
$pfFiles = Get-ChildItem "C:\Windows\Prefetch" -Force -ErrorAction SilentlyContinue
$pfSize = 0
foreach ($f in $pfFiles) { $pfSize += $f.Length }
# Only remove if > 50MB
if ($pfSize -gt 50MB) {
    $count = 0
    foreach ($f in $pfFiles) {
        Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue
        $count++
    }
    Write-Host "    Removed $count files, freed $([math]::Round($pfSize/1GB,2)) GB"
} else {
    Write-Host "    Only $([math]::Round($pfSize/1GB,2)) GB, skipping (not worth it)"
}

# 4. npm cache
Write-Host "[4] Cleaning npm cache..."
$npmBefore = (Get-ChildItem "$env:APPDATA\npm-cache" -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
if ($npmBefore -gt 0) {
    npm cache clean --force 2>&1 | Out-Null
    Write-Host "    Freed $([math]::Round($npmBefore/1GB,2)) GB"
}

$elapsed = (Get-Date) - $start
Write-Host ""
Write-Host "=== Cleanup Complete in $($elapsed.TotalSeconds) seconds ==="

# Check new free space
$freespace = (Get-PSDrive C).Free
Write-Host "New free space: $([math]::Round($freespace/1GB,2)) GB"
