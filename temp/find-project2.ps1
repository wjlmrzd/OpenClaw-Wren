[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$out = @()

# Check OpenClawWorkspace
$out += "=== D:\OpenClawWorkspace ==="
if (Test-Path "D:\OpenClawWorkspace") {
    Get-ChildItem "D:\OpenClawWorkspace" -Directory | ForEach-Object { $out += $_.Name }
} else {
    $out += "NOT FOUND"
}

# Check the hidden GUID directory
$out += ""
$out += "=== D:\4cfaf3306f4945fd95e2a03193abecf1 ==="
if (Test-Path "D:\4cfaf3306f4945fd95e2a03193abecf1") {
    Get-ChildItem "D:\4cfaf3306f4945fd95e2a03193abecf1" -Directory | ForEach-Object { $out += $_.Name }
    Get-ChildItem "D:\4cfaf3306f4945fd95e2a03193abecf1" -File | ForEach-Object { $out += $_.Name }
} else {
    $out += "NOT FOUND"
}

# Search for "my" or "project" in directory names
$out += ""
$out += "=== Search all drives for 'my' or 'project' ==="
foreach ($drive in @("C:", "D:", "E:", "H:")) {
    $result = Get-ChildItem "$drive\" -Directory -Recurse -Depth 3 -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*my*" -or $_.Name -like "*project*" -or $_.Name -like "*project*" }
    if ($result) {
        $out += "Drive $drive`:"
        $result | ForEach-Object { $out += $_.FullName }
    }
}

$out | Out-File -FilePath "D:\OpenClaw\.openclaw\workspace\temp\find-project2.txt" -Encoding UTF8
Write-Output "Done"
