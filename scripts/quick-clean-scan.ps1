$ErrorActionPreference = 'SilentlyContinue'

# Overall
$freespace = (Get-PSDrive C).Free
$total = (Get-PSDrive C).Used + $freespace
$used = (Get-PSDrive C).Used

Write-Host "========================================"
Write-Host "         C: Drive Analysis"
Write-Host "========================================"
Write-Host "Total: $([math]::Round($total/1GB,2)) GB"
Write-Host "Used:  $([math]::Round($used/1GB,2)) GB"
Write-Host "Free:  $([math]::Round($freespace/1GB,2)) GB"
Write-Host ""

# Windows Update Cache
Write-Host "[1] Windows Update Cache..."
$wu = Get-ChildItem "C:\Windows\SoftwareDistribution\Download" -Recurse -Force -ErrorAction SilentlyContinue
$wuSize = 0
foreach ($item in $wu) { $wuSize += $item.Length }
Write-Host "      Size: $([math]::Round($wuSize/1GB,2)) GB ($($wu.Count) files)"
Write-Host ""

# Windows Temp
Write-Host "[2] Windows Temp (C:\Windows\Temp)..."
$wt = Get-ChildItem "C:\Windows\Temp" -Recurse -Force -ErrorAction SilentlyContinue
$wtSize = 0
foreach ($item in $wt) { $wtSize += $item.Length }
Write-Host "      Size: $([math]::Round($wtSize/1GB,2)) GB ($($wt.Count) files)"
Write-Host ""

# User Temp
Write-Host "[3] User Temp ($env:TEMP)..."
$ut = Get-ChildItem $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue
$utSize = 0
foreach ($item in $ut) { $utSize += $item.Length }
Write-Host "      Size: $([math]::Round($utSize/1GB,2)) GB ($($ut.Count) files)"
Write-Host ""

# Recycle Bin
Write-Host "[4] Recycle Bin..."
$rbSize = 0
$rbCount = 0
try {
    $shell = New-Object -ComObject Shell.Application
    $recycler = $shell.NameSpace(0xa)
    if ($recycler) {
        $items = $recycler.Items()
        $rbCount = $items.Count
        foreach ($item in $items) { $rbSize += $item.Size }
    }
} catch {}
Write-Host "      Size: $([math]::Round($rbSize/1GB,2)) GB ($rbCount items)"
Write-Host ""

# Prefetch
Write-Host "[5] Prefetch..."
$pf = Get-ChildItem "C:\Windows\Prefetch" -Recurse -Force -ErrorAction SilentlyContinue
$pfSize = 0
foreach ($item in $pf) { $pfSize += $item.Length }
Write-Host "      Size: $([math]::Round($pfSize/1GB,2)) GB ($($pf.Count) files)"
Write-Host ""

# Log files
Write-Host "[6] Large Log Files (C:\)..."
$logFiles = @()
foreach ($ext in @("*.log","*.tmp","*.bak","*.old","*.chk")) {
    $lf = Get-ChildItem "C:\" -Filter $ext -Recurse -Force -ErrorAction SilentlyContinue -Depth 2
    foreach ($f in $lf) {
        if ($f.Length -gt 10MB) {
            $logFiles += [PSCustomObject]@{Path=$f.FullName; SizeMB=[math]::Round($f.Length/1MB,1)}
        }
    }
}
if ($logFiles.Count -gt 0) {
    $logFiles | Sort-Object SizeMB -Descending | Select-Object -First 10 | Format-Table -AutoSize
} else {
    Write-Host "      No large log files found"
}
Write-Host ""

# User folders sizes (top-level)
Write-Host "[7] User Folder Breakdown..."
$userPath = "C:\Users\Administrator"
if (Test-Path $userPath) {
    $subs = Get-ChildItem $userPath -Directory -Force -ErrorAction SilentlyContinue
    foreach ($sub in $subs) {
        $subFiles = Get-ChildItem $sub.FullName -Recurse -Force -ErrorAction SilentlyContinue
        $subSize = 0
        foreach ($f in $subFiles) { $subSize += $f.Length }
        Write-Host "      $($sub.Name): $([math]::Round($subSize/1GB,2)) GB"
    }
}
Write-Host ""

# Downloads folder
Write-Host "[8] Downloads folder..."
$dl = "C:\Users\Administrator\Downloads"
if (Test-Path $dl) {
    $dlFiles = Get-ChildItem $dl -File -Force -ErrorAction SilentlyContinue
    $dlSize = 0
    foreach ($f in $dlFiles) { $dlSize += $f.Length }
    $topDl = $dlFiles | Sort-Object Length -Descending | Select-Object -First 10
    Write-Host "      Total: $([math]::Round($dlSize/1GB,2)) GB ($($dlFiles.Count) files)"
    Write-Host "      Top files:"
    foreach ($f in $topDl) {
        Write-Host "        $([math]::Round($f.Length/1GB,2)) GB - $($f.Name)"
    }
}
Write-Host ""

# Leidian (emulator)
Write-Host "[9] Leidian (Emulator)..."
$ld = "C:\leidian"
if (Test-Path $ld) {
    $ldFiles = Get-ChildItem $ld -Recurse -Force -ErrorAction SilentlyContinue
    $ldSize = 0
    foreach ($f in $ldFiles) { $ldSize += $f.Length }
    Write-Host "      Size: $([math]::Round($ldSize/1GB,2)) GB"
}
Write-Host ""

Write-Host "========================================"
Write-Host "  SAFE TO CLEAN (with your OK):"
Write-Host "========================================"
$safeClean = $wuSize + $wtSize + $utSize + $rbSize + $pfSize
Write-Host "Windows Update: $([math]::Round($wuSize/1GB,2)) GB"
Write-Host "Windows Temp:   $([math]::Round($wtSize/1GB,2)) GB"
Write-Host "User Temp:      $([math]::Round($utSize/1GB,2)) GB"
Write-Host "Recycle Bin:    $([math]::Round($rbSize/1GB,2)) GB"
Write-Host "Prefetch:       $([math]::Round($pfSize/1GB,2)) GB"
Write-Host "----------------------------------------"
Write-Host "TOTAL SAFE:     $([math]::Round($safeClean/1GB,2)) GB"
