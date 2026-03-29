$ErrorActionPreference = 'SilentlyContinue'
Write-Host "=== Deleting AnythingLLM ==="
Write-Host ""

# Roaming
$roaming = "C:\Users\Administrator\AppData\Roaming\anythingllm-desktop"
if (Test-Path $roaming) {
    $s1 = 0
    Get-ChildItem $roaming -Recurse -Force | ForEach-Object { $s1 = $s1 + $_.Length }
    Write-Host "Roaming size: $([math]::Round($s1/1GB,2)) GB"
    Remove-Item $roaming -Recurse -Force
    Write-Host "Deleted: $roaming"
} else {
    Write-Host "Not found: $roaming"
}

# Local updater
$local = "C:\Users\Administrator\AppData\Local\anythingllm-desktop-updater"
if (Test-Path $local) {
    $s2 = 0
    Get-ChildItem $local -Recurse -Force | ForEach-Object { $s2 = $s2 + $_.Length }
    Write-Host "Local updater size: $([math]::Round($s2/1GB,2)) GB"
    Remove-Item $local -Recurse -Force
    Write-Host "Deleted: $local"
} else {
    Write-Host "Not found: $local"
}

Write-Host ""
Write-Host "=== Done ==="
