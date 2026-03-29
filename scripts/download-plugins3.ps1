$ErrorActionPreference = 'Continue'
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$vault = 'E:\software\Obsidian\vault'
$pluginsDir = Join-Path $vault '.obsidian\plugins'

function Get-GitHubLatestZip($repo) {
    $api = "https://api.github.com/repos/$repo/releases/latest"
    $headers = @{ "User-Agent" = "PowerShell" }
    try {
        $r = Invoke-RestMethod -Uri $api -Headers $headers -TimeoutSec 15
        $zipball = $r.zipball_url
        if ($zipball) {
            Write-Host "  Latest release: $($r.tag_name)"
            return $zipball
        }
    } catch {
        Write-Host "  API failed: $($_.Exception.Message)"
    }
    return $null
}

function Install-GitHubPlugin($pluginId, $repo) {
    $pluginPath = Join-Path $pluginsDir $pluginId
    if (Test-Path $pluginPath) {
        Write-Host "SKIP: $pluginId already installed"
        return $true
    }
    
    Write-Host "Getting $pluginId from $repo..."
    $zipUrl = Get-GitHubLatestZip $repo
    if (-not $zipUrl) {
        $zipUrl = "https://github.com/$repo/archive/refs/heads/main.zip"
        Write-Host "  Using main branch fallback"
    }
    
    $tmp = Join-Path $env:TEMP "$pluginId.zip"
    try {
        Write-Host "  Downloading..."
        Invoke-WebRequest -Uri $zipUrl -OutFile $tmp -TimeoutSec 30 -Headers @{ "User-Agent" = "PowerShell" }
        $sz = (Get-Item $tmp).Length
        Write-Host "  Size: $sz bytes"
        
        $exDir = Join-Path $env:TEMP "$pluginId-extract"
        if (Test-Path $exDir) { Remove-Item $exDir -Recurse -Force }
        Expand-Archive -Path $tmp -DestinationPath $exDir -Force
        
        $subDir = Get-ChildItem $exDir -Directory | Select-Object -First 1
        if ($subDir) {
            New-Item -ItemType Directory -Path $pluginPath -Force | Out-Null
            Copy-Item "$($subDir.FullName)\" $pluginPath -Recurse -Force
            $hasMain = Test-Path (Join-Path $pluginPath 'main.js')
            Write-Host "  Installed! main.js=$hasMain"
        }
        
        Remove-Item $tmp -Force
        if (Test-Path $exDir) { Remove-Item $exDir -Recurse -Force }
        return $true
    } catch {
        Write-Host "  FAILED: $($_.Exception.Message)"
        return $false
    }
}

Write-Host "=== Obsidian Plugin Installer ==="
Write-Host ""

# Calendar plugin
Install-GitHubPlugin "obsidian-calendar-plugin" "liamcain/obsidian-calendar-plugin"

Write-Host ""

# RSS Reader - try multiple repos
$rssRepos = @("degrood21/obsidian-rss-reader", "缝隙/obsidian-rss", "Karl-Gg/obsidian-rss")
foreach ($r in $rssRepos) {
    Write-Host ""
    if (Install-GitHubPlugin "obsidian-rss-reader" $r) { break }
}

Write-Host ""
Write-Host "=== Installed Plugins ==="
Get-ChildItem $pluginsDir -Directory | ForEach-Object {
    $mn = Join-Path $_.FullName 'manifest.json'
    $mj = Join-Path $_.FullName 'main.js'
    $hasMn = Test-Path $mn
    $hasMj = Test-Path $mj
    Write-Host "  $($_.Name) manifest=$hasMn main=$hasMj"
}
