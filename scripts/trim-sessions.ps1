# UTF-8 with BOM
# Trim bloated skillsSnapshot from sessions.json to prevent context bloat
$ErrorActionPreference = "SilentlyContinue"
$path = "D:\OpenClaw\.openclaw\agents\main\sessions\sessions.json"
$reportPath = "D:\OpenClaw\.openclaw\workspace\memory\sessions-trim-report.txt"

if (-not (Test-Path $path)) { exit 0 }

$raw = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
$sizeBefore = $raw.Length
$obj = $raw | ConvertFrom-Json
$count = 0

foreach ($prop in $obj.PSObject.Properties) {
    $val = $prop.Value
    if ($null -ne $val -and $val.PSObject.Properties['skillsSnapshot']) {
        $val.PSObject.Properties.Remove('skillsSnapshot')
        $count++
    }
}

$newJson = $obj | ConvertTo-Json -Depth 20
$sizeAfter = $newJson.Length
$saved = $sizeBefore - $sizeAfter

if ($saved -gt 0) {
    [System.IO.File]::WriteAllText($path, $newJson, [System.Text.Encoding]::UTF8)
    $msg = "[{0}] Trimmed {1} sessions, saved {2:N0} bytes ({3:N0} KB) -> {4:N0} KB" -f (Get-Date -Format "yyyy-MM-dd HH:mm"), $count, $saved, ($saved/1KB), ($sizeAfter/1KB)
} else {
    $msg = "[{0}] No trim needed, size: {1:N0} KB" -f (Get-Date -Format "yyyy-MM-dd HH:mm"), ($sizeAfter/1KB)
}

$msg | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host $msg
