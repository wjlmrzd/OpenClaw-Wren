# Install Obsidian community plugins for the vault
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$vault = 'E:\software\Obsidian\vault'
$obsidianDir = Join-Path $vault '.obsidian'
$pluginsDir = Join-Path $obsidianDir 'plugins'

# Step 1: Create .obsidian directory structure
if (-not (Test-Path $obsidianDir)) {
    New-Item -ItemType Directory -Path $obsidianDir -Force | Out-Null
    Write-Host "[OK] Created .obsidian directory"
} else {
    Write-Host "[OK] .obsidian directory exists"
}

if (-not (Test-Path $pluginsDir)) {
    New-Item -ItemType Directory -Path $pluginsDir -Force | Out-Null
    Write-Host "[OK] Created plugins directory"
}

# Step 2: Create community-plugins.json (list of plugin IDs to show in UI)
$pluginIds = @(
    "obsidian-calendar-plugin",
    "obsidian-rss-reader"
)
$communityJson = $pluginIds | ConvertTo-Json -Compress
Set-Content -Path (Join-Path $obsidianDir 'community-plugins.json') -Value $communityJson -Encoding UTF8
Write-Host "[OK] Created community-plugins.json: $communityJson"

# Step 3: Create enabled-plugins.json (auto-enable our plugins)
$enabledJson = $pluginIds | ConvertTo-Json -Compress
Set-Content -Path (Join-Path $obsidianDir 'enabled-plugins.json') -Value $enabledJson -Encoding UTF8
Write-Host "[OK] Created enabled-plugins.json: $enabledJson"

# Step 4: Find Obsidian executable
$exePaths = @(
    'E:\software\Obsidian\Obsidian.exe',
    "${env:LOCALAPPDATA}\Obsidian\Obsidian.exe",
    "${env:ProgramFiles}\Obsidian\Obsidian.exe"
)

$obsidianExe = $null
foreach ($p in $exePaths) {
    if (Test-Path $p) {
        $obsidianExe = $p
        break
    }
}

Write-Host ""
if ($obsidianExe) {
    Write-Host "[OK] Found Obsidian: $obsidianExe"
    
    # Step 5: Open vault with Obsidian
    Write-Host ""
    Write-Host "Opening Obsidian with vault..."
    Start-Process -FilePath $obsidianExe -ArgumentList "--open-vault `"$vault`"" -PassThru
    Write-Host "[OK] Obsidian launched"
    
    Start-Sleep -Seconds 3
    
    Write-Host ""
    Write-Host "=== Next steps in Obsidian ==="
    Write-Host "1. Wait for Obsidian to load the vault"
    Write-Host "2. Go to Settings (gear icon) > Community Plugins"
    Write-Host "3. Click 'Turn on community plugins' if prompted"
    Write-Host "4. You should see Calendar and RSS Reader in the list"
    Write-Host "5. Click install next to each one"
    Write-Host "6. Enable each plugin from the Installed tab"
} else {
    Write-Host "[WARN] Obsidian executable not found!"
    Write-Host ""
    Write-Host "Please install Obsidian from: https://obsidian.md"
    Write-Host "Install to: E:\software\Obsidian\"
    Write-Host ""
    Write-Host "After installing, run this again or open the vault manually:"
    Write-Host "  obsidian://open?vault=$vault"
}
