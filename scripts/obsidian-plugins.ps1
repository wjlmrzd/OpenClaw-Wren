# Check Obsidian installation and set up plugins
$ErrorActionPreference = 'Continue'

# Find Obsidian executable
$obsidianPaths = @(
    'E:\software\Obsidian\Obsidian.exe',
    'C:\Program Files\Obsidian\Obsidian.exe',
    "$env:LOCALAPPDATA\Obsidian\Obsidian.exe"
)
$obsidianExe = $null
foreach ($p in $obsidianPaths) {
    if (Test-Path $p) {
        $obsidianExe = $p
        Write-Host "Found Obsidian: $p"
        break
    }
}

# Create vault .obsidian directory
$vault = 'E:\software\Obsidian\vault'
$obsidianDir = Join-Path $vault '.obsidian'
$pluginsDir = Join-Path $obsidianDir 'plugins'

if (-not (Test-Path $obsidianDir)) {
    New-Item -ItemType Directory -Path $obsidianDir -Force | Out-Null
    Write-Host "Created .obsidian directory"
}
if (-not (Test-Path $pluginsDir)) {
    New-Item -ItemType Directory -Path $pluginsDir -Force | Out-Null
    Write-Host "Created plugins directory"
}

# Create community-plugins.json with our plugins
$communityPlugins = @(
    "obsidian-calendar-plugin",
    "obsidian-rss-reader"
)
$communityJson = $communityPlugins | ConvertTo-Json -Compress
Set-Content -Path (Join-Path $obsidianDir 'community-plugins.json') -Value $communityJson -Encoding UTF8
Write-Host "Created community-plugins.json"

Write-Host ''
Write-Host 'Community plugins list:'
foreach ($p in $communityPlugins) {
    Write-Host "  - $p"
}

# Download plugins
$pluginUrls = @{
    "obsidian-calendar-plugin" = "https://github.com/liamcain/obsidian-calendar-plugin"
    "obsidian-rss-reader" = "https://github.com/degrosod21/obsidian-rss-reader"
}

Write-Host ''
Write-Host 'Plugin URLs (manual install if needed):'
foreach ($p in $pluginUrls.Keys) {
    Write-Host "  $p : $($pluginUrls[$p])"
}

Write-Host ''
Write-Host 'Obsidian executable:'
if ($obsidianExe) {
    Write-Host "  Found: $obsidianExe"
} else {
    Write-Host "  Not found - please install Obsidian"
}

Write-Host ''
Write-Host 'Next steps:'
Write-Host '  1. Open Obsidian and open the vault: E:\software\Obsidian\vault'
Write-Host '  2. Enable Community Plugins in Settings > Community Plugins'
Write-Host '  3. Search and install: Calendar and RSS Reader'
