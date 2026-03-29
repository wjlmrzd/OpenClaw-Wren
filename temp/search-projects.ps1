# -*- coding: utf-8 -*-
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Check if D:\my project exists
$path1 = "D:\my project"
$path2 = "D:\my_project"
$path3 = "C:\my project"
$path4 = "C:\my_project"
$path5 = "D:\MyProject"
$path6 = "D:\myproject"

$paths = @($path1, $path2, $path3, $path4, $path5, $path6)

foreach ($p in $paths) {
    if (Test-Path $p) {
        Write-Output "FOUND: $p"
        Get-ChildItem $p -Directory | ForEach-Object { Write-Output $_.Name }
    }
}

# Also search for directories with "属性" (attribute)
Write-Output "`n=== Searching D:\ for '属性' ==="
Get-ChildItem "D:\" -Directory -Recurse -Depth 2 -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*属性*" } | Select-Object FullName

Write-Output "`n=== All D:\ root directories ==="
Get-ChildItem "D:\" -Directory | ForEach-Object { Write-Output $_.Name }
