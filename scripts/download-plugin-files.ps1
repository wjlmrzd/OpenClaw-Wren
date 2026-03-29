$ErrorActionPreference = 'Continue'
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$pluginsDir = 'E:\software\Obsidian\vault\.obsidian\plugins'
$headers = @{ "User-Agent" = "PowerShell" }

function Download-PluginFiles($pluginId, $repo, $version, $files) {
    $pluginPath = Join-Path $pluginsDir $pluginId
    if (-not (Test-Path $pluginPath)) {
        New-Item -ItemType Directory -Path $pluginPath -Force | Out-Null
    }
    
    Write-Host "Downloading $pluginId v$version..."
    foreach ($f in $files) {
        $url = "https://github.com/$repo/releases/download/$version/$f"
        $path = Join-Path $pluginPath $f
        try {
            Write-Host "  $f..."
            Invoke-WebRequest -Uri $url -OutFile $path -TimeoutSec 30 -Headers $headers
            $sz = (Get-Item $path).Length
            Write-Host "    OK ($sz bytes)"
        } catch {
            Write-Host "    FAIL: $($_.Exception.Message)"
        }
    }
}

# Calendar plugin - check latest version
Write-Host "Checking Calendar plugin..."
$apiUrl = "https://api.github.com/repos/liamcain/obsidian-calendar-plugin/releases/latest"
try {
    $r = Invoke-RestMethod -Uri $apiUrl -Headers $headers -TimeoutSec 15
    $calVersion = $r.tag_name
    Write-Host "Calendar version: $calVersion"
    
    $calFiles = @("main.js", "manifest.json", "styles.css")
    Download-PluginFiles "obsidian-calendar-plugin" "liamcain/obsidian-calendar-plugin" $calVersion $calFiles
} catch {
    Write-Host "Calendar check failed: $_"
}

Write-Host ""

# RSS plugin - check latest version
Write-Host "Checking RSS plugin..."
$apiUrl2 = "https://api.github.com/repos/joethei/obsidian-rss/releases/latest"
try {
    $r2 = Invoke-RestMethod -Uri $apiUrl2 -Headers $headers -TimeoutSec 15
    $rssVersion = $r2.tag_name
    Write-Host "RSS version: $rssVersion"
    
    # Check what files are in the RSS release
    Write-Host "RSS release assets:"
    foreach ($a in $r2.assets) {
        Write-Host "  $($a.name) - $($a.browser_download_url)"
    }
    
    $rssFiles = @("main.js", "manifest.json")
    # Try styles.css too
    Download-PluginFiles "obsidian-rss" "joethei/obsidian-rss" $rssVersion $rssFiles
} catch {
    Write-Host "RSS check failed: $_"
}

Write-Host ""
Write-Host "=== Final Plugin Status ==="
Get-ChildItem $pluginsDir -Directory | ForEach-Object {
    $mj = Test-Path (Join-Path $_.FullName 'main.js')
    $mn = Test-Path (Join-Path $_.FullName 'manifest.json')
    $ss = Test-Path (Join-Path $_.FullName 'styles.css')
    $szMj = if (Test-Path (Join-Path $_.FullName 'main.js')) { (Get-Item (Join-Path $_.FullName 'main.js')).Length } else { 0 }
    Write-Host "  $($_.Name) main.js=$mj($szMj) manifest=$mn styles.css=$ss"
}
