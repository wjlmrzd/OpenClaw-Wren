[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# List ALL directories on D: including hidden
Write-Output "=== D:\ ALL directories ==="
Get-ChildItem "D:\" -Directory -Force | ForEach-Object { 
    Write-Output ($_.Name + " | Hidden=" + $_.Attributes.ToString().Contains("Hidden")) 
}

# List with full details
Write-Output ""
Write-Output "=== D:\ with full details ==="
Get-ChildItem "D:\" -Directory -Force | Select-Object Name, FullName, Attributes | Format-Table -AutoSize
