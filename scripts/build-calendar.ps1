$ErrorActionPreference = 'Continue'
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Strategy: Download pre-built files from jsDelivr CDN (served from npm)
$pluginsDir = 'E:\software\Obsidian\vault\.obsidian\plugins'

# Calendar plugin - npm package: obsidian-calendar-plugin
$calDir = Join-Path $pluginsDir 'obsidian-calendar-plugin'
if (-not (Test-Path $calDir)) { New-Item -ItemType Directory -Path $calDir -Force | Out-Null }

Write-Host "Downloading Calendar plugin files from jsDelivr..."
$calFiles = @(
    @{Url="https://cdn.jsdelivr.net/npm/obsidian-calendar-plugin@latest/main.js"; Dest="main.js"},
    @{Url="https://cdn.jsdelivr.net/npm/obsidian-calendar-plugin@latest/manifest.json"; Dest="manifest.json"},
    @{Url="https://cdn.jsdelivr.net/npm/obsidian-calendar-plugin@latest/styles.css"; Dest="styles.css"}
)

foreach ($f in $calFiles) {
    $path = Join-Path $calDir $f.Dest
    Write-Host "  $($f.Dest)..."
    try {
        Invoke-WebRequest -Uri $f.Url -OutFile $path -TimeoutSec 20 -Headers @{ "User-Agent" = "PowerShell" }
        $sz = (Get-Item $path).Length
        Write-Host "    OK ($sz bytes)"
    } catch {
        Write-Host "    FAILED: $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "Downloading RSS plugin files..."
$rssDir = Join-Path $pluginsDir 'obsidian-rss-reader'
if (-not (Test-Path $rssDir)) { New-Item -ItemType Directory -Path $rssDir -Force | Out-Null }

# Try multiple RSS plugin npm packages
$rssPackages = @("obsidian-rss-reader", "obsidian-feeds", "@tim-hub/obsidian-rss")
$rssFiles = $null

foreach ($pkg in $rssPackages) {
    Write-Host "  Trying npm package: $pkg"
    $testUrl = "https://cdn.jsdelivr.net/npm/$pkg@latest/manifest.json"
    try {
        $r = Invoke-WebRequest -Uri $testUrl -TimeoutSec 10 -Headers @{ "User-Agent" = "PowerShell" }
        if ($r.StatusCode -eq 200) {
            Write-Host "  Found: $pkg"
            $rssFiles = @(
                @{Url="https://cdn.jsdelivr.net/npm/$pkg@latest/main.js"; Dest="main.js"},
                @{Url="https://cdn.jsdelivr.net/npm/$pkg@latest/manifest.json"; Dest="manifest.json"}
            )
            break
        }
    } catch {
        Write-Host "    Not found"
    }
}

if ($rssFiles) {
    foreach ($f in $rssFiles) {
        $path = Join-Path $rssDir $f.Dest
        Write-Host "  $($f.Dest)..."
        try {
            Invoke-WebRequest -Uri $f.Url -OutFile $path -TimeoutSec 20 -Headers @{ "User-Agent" = "Power-Agent" }
            $sz = (Get-Item $path).Length
            Write-Host "    OK ($sz bytes)"
        } catch {
            Write-Host "    FAILED: $($_.Exception.Message)"
        }
    }
} else {
    Write-Host "  No RSS plugin found on npm"
}

Write-Host ""
Write-Host "=== Results ==="
Get-ChildItem $pluginsDir -Directory | ForEach-Object {
    $m = Test-Path (Join-Path $_.FullName 'manifest.json')
    $j = Test-Path (Join-Path $_.FullName 'main.js')
    $s = Test-Path (Join-Path $_.FullName 'styles.css')
    Write-Host "  $($_.Name) manifest=$m main=$j styles=$s"
}
