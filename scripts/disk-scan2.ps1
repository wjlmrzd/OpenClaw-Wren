$ErrorActionPreference = 'SilentlyContinue'
$start = Get-Date
$results = @()

function Get-FolderSize {
    param([string]$Path, [string]$Name)
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $size = (Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $sw.Stop()
    [PSCustomObject]@{
        Folder = $Name
        SizeGB = [math]::Round($size/1GB, 2)
        Secs = $sw.Elapsed.TotalSeconds
    }
}

# Run each scan in sequence but report progress
$folders = @(
    "C:\Users", "C:\Windows", "C:\Program Files", "C:\Program Files (x86)",
    "C:\Intel", "C:\Autodesk", "C:\leidian", "C:\inetpub", "C:\tmp"
)

foreach ($f in $folders) {
    if (Test-Path $f) {
        $name = Split-Path $f -Leaf
        Write-Host "Scanning $name..."
        $results += Get-FolderSize -Path $f -Name $name
    }
}

# Temp files sizes
Write-Host "Scanning Temp..."
$winTemp = Get-FolderSize -Path "C:\Windows\Temp" -Name "Windows\Temp"
$userTemp = Get-FolderSize -Path $env:TEMP -Name "User Temp"
$results += $winTemp, $userTemp

# Windows Update
Write-Host "Scanning WinUpdate..."
$wu = Get-FolderSize -Path "C:\Windows\SoftwareDistribution\Download" -Name "WinUpdate Cache"
$results += $wu

# Recycle Bin
Write-Host "Checking Recycle Bin..."
$rbSize = 0
try {
    $shell = New-Object -ComObject Shell.Application
    $recycler = $shell.NameSpace(0xa)
    if ($recycler) {
        $recycler.Items() | ForEach-Object { $rbSize += $_.Size }
    }
} catch {}

$results += [PSCustomObject]@{Folder="Recycle Bin"; SizeGB=[math]::Round($rbSize/1GB,2); Secs=0}

# Large files in Users
Write-Host "Scanning large user files..."
$largeFiles = @()
Get-ChildItem "C:\Users" -Recurse -File -ErrorAction SilentlyContinue | 
    Sort-Object Length -Descending | Select-Object -First 20 FullName, @{N='SizeGB';E={[math]::Round($_.Length/1GB,3)}}, LastWriteTime |
    ForEach-Object { $largeFiles += $_ }

$results | Sort-Object SizeGB -Descending | Format-Table -AutoSize
Write-Host ""
Write-Host "=== Top 20 Largest Files ==="
$largeFiles | Format-Table -AutoSize

$elapsed = (Get-Date) - $start
Write-Host ""
Write-Host "Scan completed in $($elapsed.TotalSeconds) seconds"
