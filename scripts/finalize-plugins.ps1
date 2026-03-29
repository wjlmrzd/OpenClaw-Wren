$ErrorActionPreference = 'Continue'
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$vault = 'E:\software\Obsidian\vault'
$obsidianDir = Join-Path $vault '.obsidian'

# Update community-plugins.json with correct plugin IDs
$pluginIds = @(
    "obsidian-calendar-plugin",
    "obsidian-rss"
)
$communityJson = $pluginIds | ConvertTo-Json -Compress
Set-Content -Path (Join-Path $obsidianDir 'community-plugins.json') -Value $communityJson -Encoding UTF8 -NoNewline
Write-Host "Updated community-plugins.json: $communityJson"

# Update enabled-plugins.json
$enabledJson = $pluginIds | ConvertTo-Json -Compress
Set-Content -Path (Join-Path $obsidianDir 'enabled-plugins.json') -Value $enabledJson -Encoding UTF8 -NoNewline
Write-Host "Updated enabled-plugins.json: $enabledJson"

# Verify final state
Write-Host ""
Write-Host "=== Plugin Directories ==="
$pluginsDir = Join-Path $obsidianDir 'plugins'
Get-ChildItem $pluginsDir -Directory | ForEach-Object {
    $mj = Test-Path (Join-Path $_.FullName 'main.js')
    $mn = Test-Path (Join-Path $_.FullName 'manifest.json')
    $ss = Test-Path (Join-Path $_.FullName 'styles.css')
    if ($mj -and $mn) {
        Write-Host "  $($_.Name) [OK] main.js manifest.json styles.css=$ss"
    } else {
        Write-Host "  $($_.Name) [INCOMPLETE] main.js=$mj manifest=$mn"
    }
}

# Also verify jsDelivr CDN fallback is available
Write-Host ""
Write-Host "=== Testing CDN availability ==="
try {
    $test = Invoke-WebRequest -Uri "https://cdn.jsdelivr.net/npm/obsidian-calendar-plugin@latest/manifest.json" -TimeoutSec 10 -UseBasicParsing
    Write-Host "  jsDelivr Calendar: $($test.StatusCode)"
} catch {
    Write-Host "  jsDelivr Calendar: FAIL"
}

Write-Host ""
Write-Host "Done! Restarting Obsidian to load plugins..."
