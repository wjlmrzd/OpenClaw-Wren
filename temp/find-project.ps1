# -*- coding: utf-8 -*-
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Search for directories containing keywords
$patterns = @("属性", "属性块", "转属性", "project", "my")
$results = @()

foreach ($dir in Get-ChildItem "D:\" -Directory) {
    foreach ($pattern in $patterns) {
        if ($dir.Name -match $pattern) {
            $results += $dir.FullName
            break
        }
    }
}

if ($results.Count -gt 0) {
    Write-Output "Found matching directories:"
    foreach ($r in $results) {
        Write-Output $r
    }
} else {
    Write-Output "No matching directories found in D:\"
    Write-Output "All directories in D:\"
    Get-ChildItem "D:\" -Directory | ForEach-Object { Write-Output $_.Name }
}
