$ErrorActionPreference = 'Continue'
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$pluginsDir = 'E:\software\Obsidian\vault\.obsidian\plugins'

# Plugin definitions: id -> GitHub repo (use release zipball_url)
$pluginDefs = @{
    "obsidian-calendar-plugin" = @{
        Repo = "liamcain/obsidian-calendar-plugin"
        ReleaseApi = "https://api.github.com/repos/liamcain/obsidian-calendar-plugin/releases/latest"
    }
    "obsidian-rss" = @{
        Repo = "joethei/obsidian-rss"
        ReleaseApi = "https://api.github.com/repos/joethei/obsidian-rss/releases/latest"
    }
}

function Get-ReleaseZipUrl($apiUrl) {
    try {
        $headers = @{ "User-Agent" = "PowerShell" }
        $r = Invoke-RestMethod -Uri $apiUrl -Headers $headers -TimeoutSec 15
        # Get zipball_url from latest release
        if ($r.zipball_url) {
            Write-Host "  Release: $($r.tag_name)"
            return $r.zipball_url
        }
    } catch {
        Write-Host "  API error: $($_.Exception.Message)"
    }
    return $null
}

function Install-PluginFromZip($pluginId, $repo, $zipUrl) {
    $pluginPath = Join-Path $pluginsDir $pluginId
    if ((Test-Path $pluginPath) -and (Get-ChildItem $pluginPath -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq 'main.js' })) {
        Write-Host "[SKIP] $pluginId already has main.js"
        return $true
    }
    
    Write-Host "Downloading $pluginId..."
    $tmpZip = Join-Path $env:TEMP "$pluginId-release.zip"
    try {
        Invoke-WebRequest -Uri $zipUrl -OutFile $tmpZip -TimeoutSec 60 -Headers @{ "User-Agent" = "PowerShell" }
        $sz = (Get-Item $tmpZip).Length
        Write-Host "  Downloaded: $sz bytes"
        
        # Extract to temp
        $extractBase = Join-Path $env:TEMP "$pluginId-extract"
        if (Test-Path $extractBase) { Remove-Item $extractBase -Recurse -Force }
        New-Item -ItemType Directory -Path $extractBase -Force | Out-Null
        
        Expand-Archive -Path $tmpZip -DestinationPath $extractBase -Force
        
        # Find the extracted folder
        $extracted = Get-ChildItem $extractBase -Directory | Select-Object -First 1
        if ($extracted) {
            Write-Host "  Extracted: $($extracted.Name)"
            
            # Create plugin directory
            if (Test-Path $pluginPath) { Remove-Item $pluginPath -Recurse -Force }
            New-Item -ItemType Directory -Path $pluginPath -Force | Out-Null
            
            # Copy all files from extracted folder
            Copy-Item "$($extracted.FullName)\*" $pluginPath -Recurse -Force
            
            # Check for main.js
            $mainJs = Join-Path $pluginPath 'main.js'
            $manifest = Join-Path $pluginPath 'manifest.json'
            
            if (Test-Path $mainJs) {
                Write-Host "  [OK] main.js found"
            } else {
                Write-Host "  [WARN] main.js NOT found!"
                # Check if there's a build/ dir
                Get-ChildItem $pluginPath -Directory | ForEach-Object {
                    Write-Host "    Subdir: $($_.Name)"
                    $mj = Join-Path $_.FullName 'main.js'
                    if (Test-Path $mj) {
                        Write-Host "    Found main.js in subdir!"
                        Copy-Item $mj $pluginPath -Force
                    }
                }
            }
            
            if (Test-Path $manifest) {
                Write-Host "  [OK] manifest.json found"
            } else {
                Write-Host "  [WARN] manifest.json NOT found"
            }
        }
        
        Remove-Item $tmpZip -Force
        if (Test-Path $extractBase) { Remove-Item $extractBase -Recurse -Force }
        
    } catch {
        Write-Host "  FAILED: $($_.Exception.Message)"
    }
}

Write-Host "=== Installing from GitHub Releases ==="
Write-Host ""

foreach ($pname in $pluginDefs.Keys) {
    $def = $pluginDefs[$pname]
    Write-Host "=== $pname ==="
    $zipUrl = Get-ReleaseZipUrl $def.ReleaseApi
    if ($zipUrl) {
        Install-PluginFromZip $pname $def.Repo $zipUrl
    } else {
        Write-Host "  Could not get release URL"
    }
    Write-Host ""
}

Write-Host "=== Installed Plugins ==="
Get-ChildItem $pluginsDir -Directory | ForEach-Object {
    $mj = Test-Path (Join-Path $_.FullName 'main.js')
    $mn = Test-Path (Join-Path $_.FullName 'manifest.json')
    Write-Host "  $($_.Name) main.js=$mj manifest=$mn"
}
