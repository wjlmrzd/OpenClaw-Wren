$ErrorActionPreference = 'SilentlyContinue'
Write-Host "=== C: Drive Analysis ==="
Write-Host ""

# Overall
$freespace = (Get-PSDrive C).Free
$total = (Get-PSDrive C).Used + $freespace
Write-Host "Total: $([math]::Round($total/1GB,2)) GB | Used: $([math]::Round((Get-PSDrive C).Used/1GB,2)) GB | Free: $([math]::Round($freespace/1GB,2)) GB"
Write-Host ""

# Top-level folders
Write-Host "=== Top-level Folders ==="
Get-ChildItem 'C:\' -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $folder = $_
    $size = (Get-ChildItem $folder.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    [PSCustomObject]@{
        Folder = $folder.Name
        SizeGB = [math]::Round($size/1GB, 2)
    }
} | Sort-Object SizeGB -Descending | Format-Table -AutoSize

Write-Host ""
Write-Host "=== Temp Files ==="
$tempSize = 0
Get-ChildItem 'C:\Windows\Temp' -Recurse -ErrorAction SilentlyContinue | ForEach-Object { $tempSize += $_.Length }
$userTemp = "$env:TEMP"
$userTempSize = 0
Get-ChildItem $userTemp -Recurse -ErrorAction SilentlyContinue | ForEach-Object { $userTempSize += $_.Length }
Write-Host "Windows\Temp: $([math]::Round($tempSize/1GB,2)) GB"
Write-Host "User Temp ($userTemp): $([math]::Round($userTempSize/1GB,2)) GB"
Write-Host "Total Temp: $([math]::Round(($tempSize+$userTempSize)/1GB,2)) GB"

Write-Host ""
Write-Host "=== Windows Update Cache ==="
$wuCat = "C:\Windows\SoftwareDistribution\Download"
$wuSize = (Get-ChildItem $wuCat -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
Write-Host "SoftwareDistribution: $([math]::Round($wuSize/1GB,2)) GB"

Write-Host ""
Write-Host "=== Recycle Bin ==="
$shell = New-Object -ComObject Shell.Application
$recycler = $shell.NameSpace(0xa)
if ($recycler) {
    $rbSize = 0
    $recycler.Items() | ForEach-Object { $rbSize += $_.Size }
    Write-Host "Recycle Bin (C:): $([math]::Round($rbSize/1GB,2)) GB"
}

Write-Host ""
Write-Host "=== User Profiles ==="
Get-ChildItem 'C:\Users' -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $folder = $_
    $size = (Get-ChildItem $folder.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    [PSCustomObject]@{
        User = $folder.Name
        SizeGB = [math]::Round($size/1GB, 2)
    }
} | Sort-Object SizeGB -Descending | Format-Table -AutoSize
