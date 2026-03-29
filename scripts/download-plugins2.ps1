$ErrorActionPreference = 'Continue'
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$vault = 'E:\software\Obsidian\vault'
$pluginsDir = Join-Path $vault '.obsidian\plugins'

Write-Host "Plugins dir: $pluginsDir"

# Calendar plugin
$calUrl = 'https://github.com/liamcain/obsidian-calendar-plugin/archive/refs/heads/main.zip'
$calPath = Join-Path $pluginsDir 'obsidian-calendar-plugin'
Write-Host "Downloading calendar plugin..."

if (Test-Path $calPath) {
    Write-Host "Calendar already installed"
} else {
    $tmp = Join-Path $env:TEMP 'cal.zip'
    try {
        Invoke-WebRequest -Uri $calUrl -OutFile $tmp -TimeoutSec 30
        Write-Host "Downloaded"
        $exDir = Join-Path $env:TEMP 'calext'
        if (Test-Path $exDir) { Remove-Item $exDir -Recurse -Force }
        Expand-Archive -Path $tmp -DestinationPath $exDir -Force
        $src = Get-ChildItem $exDir -Directory | Select-Object -First 1
        if ($src) {
            New-Item -ItemType Directory -Path $calPath -Force | Out-Null
            Copy-Item "$($src.FullName)\*" $calPath -Recurse -Force
            Write-Host "Installed to obsidian-calendar-plugin"
        }
        Remove-Item $tmp -Force
        if (Test-Path $exDir) { Remove-Item $exDir -Recurse -Force }
    } catch {
        Write-Host "Calendar failed: $_"
    }
}

# RSS plugin
$rssUrl = 'https://github.com/degrood21/obsidian-rss-reader/archive/refs/heads/main.zip'
$rssPath = Join-Path $pluginsDir 'obsidian-rss-reader'
Write-Host "Downloading RSS plugin..."

if (Test-Path $rssPath) {
    Write-Host "RSS already installed"
} else {
    $tmp2 = Join-Path $env:TEMP 'rss.zip'
    try {
        Invoke-WebRequest -Uri $rssUrl -OutFile $tmp2 -TimeoutSec 30
        Write-Host "Downloaded"
        $exDir2 = Join-Path $env:TEMP 'rssext'
        if (Test-Path $exDir2) { Remove-Item $exDir2 -Recurse -Force }
        Expand-Archive -Path $tmp2 -DestinationPath $exDir2 -Force
        $src2 = Get-ChildItem $exDir2 -Directory | Select-Object -First 1
        if ($src2) {
            New-Item -ItemType Directory -Path $rssPath -Force | Out-Null
            Copy-Item "$($src2.FullName)\*" $rssPath -Recurse -Force
            Write-Host "Installed to obsidian-rss-reader"
        }
        Remove-Item $tmp2 -Force
        if (Test-Path $exDir2) { Remove-Item $exDir2 -Recurse -Force }
    } catch {
        Write-Host "RSS failed: $_"
    }
}

Write-Host "Done. Checking installed plugins:"
Get-ChildItem $pluginsDir -Directory | ForEach-Object {
    $mj = Join-Path $_.FullName 'main.js'
    $mn = Join-Path $_.FullName 'manifest.json'
    $hasMj = Test-Path $mj
    $hasMn = Test-Path $mn
    Write-Host "  $_ (main=$hasMj, manifest=$hasMn)"
}
