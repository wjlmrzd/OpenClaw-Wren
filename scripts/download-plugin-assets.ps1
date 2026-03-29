$ErrorActionPreference = 'Continue'
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$pluginsDir = 'E:\software\Obsidian\vault\.obsidian\plugins'

# Check what assets are available in the Calendar plugin release
Write-Host "Checking Calendar plugin release assets..."
$headers = @{ "User-Agent" = "PowerShell" }
$apiUrl = "https://api.github.com/repos/liamcain/obsidian-calendar-plugin/releases/latest"
try {
    $r = Invoke-RestMethod -Uri $apiUrl -Headers $headers -TimeoutSec 15
    Write-Host "Tag: $($r.tag_name)"
    Write-Host "Assets count: $($r.assets.Count)"
    foreach ($a in $r.assets) {
        Write-Host "  Asset: $($a.name) - $($a.browser_download_url)"
    }
    foreach ($a in $r.assets) {
        if ($a.name -match "\.zip" -or $a.name -match "main\.js") {
            Write-Host "Found downloadable: $($a.name)"
            
            $pluginPath = Join-Path $pluginsDir 'obsidian-calendar-plugin'
            if (Test-Path $pluginPath) { Remove-Item $pluginPath -Recurse -Force }
            New-Item -ItemType Directory -Path $pluginPath -Force | Out-Null
            
            $tmp = Join-Path $env:TEMP "cal-asset.zip"
            Write-Host "Downloading..."
            Invoke-WebRequest -Uri $a.browser_download_url -OutFile $tmp -TimeoutSec 60 -Headers $headers
            Write-Host "Extracting..."
            Expand-Archive -Path $tmp -DestinationPath $pluginPath -Force
            Remove-Item $tmp -Force
            
            $mj = Join-Path $pluginPath 'main.js'
            if (Test-Path $mj) {
                Write-Host "SUCCESS: main.js found!"
            } else {
                Get-ChildItem $pluginPath -Recurse -File | Where-Object { $_.Name -match 'main' } | ForEach-Object {
                    Write-Host "Found: $($_.FullName)"
                }
            }
        }
    }
} catch {
    Write-Host "Error: $_"
}

Write-Host ""
Write-Host "=== Current Plugins Status ==="
Get-ChildItem $pluginsDir -Directory | ForEach-Object {
    $mj = Test-Path (Join-Path $_.FullName 'main.js')
    $mn = Test-Path (Join-Path $_.FullName 'manifest.json')
    $ss = Test-Path (Join-Path $_.FullName 'styles.css')
    Write-Host "  $($_.Name) main.js=$mj manifest=$mn styles.css=$ss"
}
