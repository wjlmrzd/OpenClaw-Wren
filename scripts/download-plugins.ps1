# Direct plugin download - bypass UI
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Continue'

$vault = 'E:\software\Obsidian\vault'
$pluginsDir = Join-Path $vault '.obsidian\plugins'

# Plugin repos with their main branch source download URLs
$pluginDownloads = @{
    "obsidian-calendar-plugin" = "https://github.com/liamcain/obsidian-calendar-plugin/archive/refs/heads/main.zip"
    "obsidian-rss-reader" = "https://github.com/degrood21/obsidian-rss-reader/archive/refs/heads/main.zip"
}

# Also try npm CDN as backup
$npmCdns = @{
    "obsidian-calendar-plugin" = "https://cdn.jsdelivr.net/gh/liamcain/obsidian-calendar-plugin@main/main.js"
    "obsidian-rss-reader" = "https://cdn.jsdelivr.net/gh/degrood21/obsidian-rss-reader@main/main.js"
}

function Install-PluginFromUrl($pluginId, $url, $fallbackUrl) {
    $pluginPath = Join-Path $pluginsDir $pluginId
    if (Test-Path $pluginPath) {
        Write-Host "[SKIP] $pluginId already installed"
        return $true
    }
    
    Write-Host "Downloading $pluginId from GitHub..."
    $zipPath = Join-Path $env:TEMP "$pluginId-src.zip"
    
    try {
        Invoke-WebRequest -Uri $url -OutFile $zipPath -TimeoutSec 30 -Headers @{ "User-Agent" = "PowerShell" }
        Write-Host "  Downloaded ($((Get-Item $zipPath).Length) bytes)"
        
        # Extract
        $extractDir = Join-Path $env:TEMP "$pluginId-extract"
        if (Test-Path $extractDir) { Remove-Item $extractDir -Force -Recurse }
        Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
        
        # Find the actual source folder (pluginId-main or pluginId-master)
        $extracted = Get-ChildItem $extractDir -Directory | Select-Object -First 1
        if ($extracted) {
            New-Item -ItemType Directory -Path $pluginPath -Force | Out-Null
            Copy-Item "$($extracted.FullName)\*" $pluginPath -Recurse -Force
            Write-Host "  Installed to: $pluginPath"
            
            # Verify main.js exists
            if (Test-Path (Join-Path $pluginPath 'main.js')) {
                Write-Host "  [OK] main.js found"
            } else {
                Write-Host "  [WARN] main.js NOT found - checking files..."
                Get-ChildItem $pluginPath | ForEach-Object { Write-Host "    $($_.Name)" }
            }
        }
        
        # Cleanup
        Remove-Item $zipPath -Force
        if (Test-Path $extractDir) { Remove-Item $extractDir -Force -Recurse }
        
        return $true
    } catch {
        Write-Host "  FAILED: $($_.Exception.Message)"
        
        # Try npm CDN as fallback
        Write-Host "  Trying npm CDN fallback..."
        try {
            $jsUrl = $npmCdns[$pluginId]
            $jsPath = Join-Path $pluginPath 'main.js'
            New-Item -ItemType Directory -Path $pluginPath -Force | Out-Null
            Invoke-WebRequest -Uri $jsUrl -OutFile $jsPath -TimeoutSec 30 -Headers @{ "User-Agent" = "PowerShell" }
            Write-Host "  [OK] Downloaded main.js from CDN"
            return $true
        } catch {
            Write-Host "  CDN also failed"
            return $false
        }
    }
}

Write-Host "=== Installing Obsidian Community Plugins ==="
Write-Host "Plugins dir: $pluginsDir"
Write-Host ""

$results = @{}
foreach ($pid in $pluginDownloads.Keys) {
    $url = $pluginDownloads[$pid]
    $results[$pid] = Install-PluginFromUrl $pid $url $null
}

Write-Host ""
Write-Host "=== Installation Results ==="
foreach ($pid in $results.Keys) {
    $status = if ($results[$pid]) { "[OK]" } else { "[FAIL]" }
    Write-Host "$status $pid"
}

Write-Host ""
Write-Host "Installed plugins:"
if (Test-Path $pluginsDir) {
    Get-ChildItem $pluginsDir -Directory | ForEach-Object {
        $hasMain = Test-Path (Join-Path $_.FullName 'main.js')
        $hasManifest = Test-Path (Join-Path $_.FullName 'manifest.json')
        Write-Host "  $($_.Name) (main.js=$hasMain, manifest=$hasManifest)")
    }
}
