# Find LCM/summary data in sessions.json
$path = "D:\OpenClaw\.openclaw\agents\main\sessions\sessions.json"
if (Test-Path $path) {
    $content = Get-Content $path -Raw -ErrorAction SilentlyContinue
    # Check if it contains LCM-related data
    if ($content -match "sum_|_lcm|summary|compacted") {
        Write-Host "Found LCM/summary references in sessions.json"
        $json = $content | ConvertFrom-Json
        $json.PSObject.Properties | Select-Object -First 10 | ForEach-Object {
            Write-Host "Key: $($_.Name) = $($_.Value | ConvertTo-Json -Compress -Depth 1)"
        }
    } else {
        Write-Host "No LCM/summary references found in sessions.json"
        Write-Host "File size: $((Get-Item $path).Length) bytes"
    }
}

# Check graph-memory plugin storage
$gmPath = "D:\OpenClaw\.openclaw\workspace\plugins-graph-memory"
Get-ChildItem $gmPath -Recurse -Depth 3 -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match "summary|node|graph|store|db|sqlite|compact" } |
    Select-Object FullName, Length
