[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$out = @()
$out += "=== E:\ ==="
Get-ChildItem "E:\" -Directory | ForEach-Object { $out += $_.Name }
$out += ""
$out += "=== D:\my project (if exists) ==="
if (Test-Path "D:\my project") {
    Get-ChildItem "D:\my project" -Directory | ForEach-Object { $out += $_.Name }
} else {
    $out += "NOT FOUND"
}
$out += ""
$out += "=== Search all drives for directories ==="
$drives = Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Name
foreach ($drive in $drives) {
    $out += "Drive $drive`:"
    Get-ChildItem "$drive`:" -Directory -ErrorAction SilentlyContinue | ForEach-Object { 
        if ($_.Name -ne $null) { $out += "  " + $_.Name } 
    }
}

$out | Out-File -FilePath "D:\OpenClaw\.openclaw\workspace\temp\dirs.txt" -Encoding UTF8
Write-Output "Done"
