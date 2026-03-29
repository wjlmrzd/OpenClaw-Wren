# Download and install Obsidian community plugins
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$vault = 'E:\software\Obsidian\vault'
$obsidianDir = Join-Path $vault '.obsidian'
$pluginsDir = Join-Path $obsidianDir 'plugins'

# Create directories
if (-not (Test-Path $obsidianDir)) {
    New-Item -ItemType Directory -Path $obsidianDir -Force | Out-Null
}
if (-not (Test-Path $pluginsDir)) {
    New-Item -ItemType Directory -Path $pluginsDir -Force | Out-Null
}
Write-Host "Directories ready"

# Plugin definitions: id -> repo
$plugins = @{
    "obsidian-calendar-plugin" = @{
        Repo = "liamcain/obsidian-calendar-plugin"
        MainFile = "main.js"
    }
    "obsidian-rss-reader" = @{
        Repo = "degrood21/obsidian-rss-reader"
        MainFile = "main.js"
    }
}

# Get latest release asset download URL
function Get-LatestReleaseUrl($repo) {
    $apiUrl = "https://api.github.com/repos/$repo/releases/latest"
    try {
        $resp = Invoke-RestMethod -Uri $apiUrl -TimeoutSec 15 -Headers @{ "User-Agent" = "PowerShell" }
        $assets = $resp.assets
        # Find the .zip or .tar.gz asset
        $zipAsset = $assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
        if ($zipAsset) {
            return $zipAsset.browser_download_url
        }
        # Fallback: try source zip
        return "https://github.com/$repo/archive/refs/heads/main.zip"
    } catch {
        return "https://github.com/$repo/archive/refs/heads/main.zip"
    }
}

foreach ($pluginId in $plugins.Keys) {
    $p = $plugins[$pluginId]
    Write-Host ""
    Write-Host "=== $pluginId ==="
    Write-Host "Repo: $($p.Repo)"
    
    $pluginTargetDir = Join-Path $pluginsDir $pluginId
    if (Test-Path $pluginTargetDir) {
        Write-Host "Already installed, skipping download"
        continue
    }
    
    $url = Get-LatestReleaseUrl $p.Repo
    Write-Host "Downloading from: $url"
    
    try {
        $zipPath = Join-Path $env:TEMP "$pluginId.zip"
        Invoke-WebRequest -Uri $url -OutFile $zipPath -TimeoutSec 30 -Headers @{ "User-Agent" = "PowerShell" }
        Write-Host "Downloaded, extracting..."
        
        # Extract
        Expand-Archive -Path $zipPath -DestinationPath $pluginsDir -Force
        
        # Find extracted folder and move to correct location
        $tempExtract = Join-Path $pluginsDir "$($pluginId)-main"
        if (Test-Path $tempExtract) {
            New-Item -ItemType Directory -Path $pluginTargetDir -Force | Out-Null
            Move-Item "$tempExtract\*" $pluginTargetDir -Force
            Remove-Item $tempExtract -Force -Recurse
        } else {
            # Try another pattern
            $subfolders = Get-ChildItem $pluginsDir -Directory | Where-Object { $_.Name -like "*$pluginId*" }
            foreach ($sf in $subfolders) {
                if ($sf.FullName -ne $pluginTargetDir) {
                    New-Item -ItemType Directory -Path $pluginTargetDir -Force | Out-Null
                    Move-Item "$($sf.FullName)\*" $pluginTargetDir -Force
                    Remove-Item $sf.FullName -Force -Recurse
                    break
                }
            }
        }
        
        # Cleanup
        if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
        
        Write-Host "Installed: $pluginId"
    } catch {
        Write-Host "Failed: $($_.Exception.Message)"
    }
}

# Update community-plugins.json
Write-Host ""
Write-Host "=== Updating community-plugins.json ==="
$pluginList = $plugins.Keys | ForEach-Object { $_ }
$communityJson = $pluginList | ConvertTo-Json -Compress
Set-Content -Path (Join-Path $obsidianDir 'community-plugins.json') -Value $communityJson -Encoding UTF8
Write-Host "community-plugins.json: $communityJson"

Write-Host ""
Write-Host "=== Done ==="
Write-Host "Open Obsidian vault at: $vault"
Write-Host "Go to Settings > Community Plugins > Turn on restricted mode toggle"
Write-Host "Then install the plugins from the Community Plugins list"
