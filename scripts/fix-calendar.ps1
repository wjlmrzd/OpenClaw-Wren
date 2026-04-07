$ErrorActionPreference = 'Continue'
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Clean up and try building from source
$pluginsDir = 'E:\software\Obsidian\vault\.obsidian\plugins'
$calDir = Join-Path $pluginsDir 'obsidian-calendar-plugin'

Write-Host "Checking calendar plugin source..."
$srcDirs = Get-ChildItem $calDir -Directory -ErrorAction SilentlyContinue
if ($srcDirs) {
    $srcDir = $srcDirs[0].FullName
    Write-Host "Source: $srcDir"
    
    # Check if there's a build directory or need to build
    $buildDir = Join-Path $srcDir 'build'
    $distDir = Join-Path $srcDir 'dist'
    
    if (Test-Path $buildDir) {
        Write-Host "build/ dir found"
        $mainInBuild = Join-Path $buildDir 'main.js'
        if (Test-Path $mainInBuild) {
            Write-Host "main.js found in build/! Copying to plugin dir..."
            Copy-Item $buildDir "$calDir\build" -Recurse -Force
            # Move main.js up to root
            Copy-Item $mainInBuild $calDir -Force
            $style = Join-Path $buildDir 'styles.css'
            if (Test-Path $style) { Copy-Item $style $calDir -Force }
        }
    }
    
    if (Test-Path $distDir) {
        Write-Host "dist/ dir found"
        $mainInDist = Join-Path $distDir 'main.js'
        if (Test-Path $mainInDist) {
            Write-Host "main.js found in dist/! Copying to plugin dir..."
            Copy-Item $distDir "$calDir\dist" -Recurse -Force
            Copy-Item $mainInDist $calDir -Force
        }
    }
    
    # Check for manifest.json in source
    $manifestSrc = Join-Path $srcDir 'manifest.json'
    if (Test-Path $manifestSrc) {
        Write-Host "manifest.json found"
        Copy-Item $manifestSrc $calDir -Force
    }
    
    # Check package.json for main entry
    $pkg = Join-Path $srcDir 'package.json'
    if (Test-Path $pkg) {
        Write-Host "package.json found"
        Copy-Item $pkg $calDir -Force
    }
    
    # Try building if no build exists
    if (-not (Test-Path (Join-Path $calDir 'main.js'))) {
        Write-Host "No main.js found - attempting to build..."
        
        # Set npm registry to use proxy
        $npmProxy = "http://127.0.0.1:7897"
        Write-Host "Setting npm proxy to: $npmProxy"
        
        Push-Location $srcDir
        try {
            npm config set proxy $npmProxy 2>&1 | Out-Null
            npm config set https-proxy $npmProxy 2>&1 | Out-Null
            Write-Host "Installing dependencies..."
            npm install 2>&1 | Out-Null
            Write-Host "Building..."
            $buildOut = npm run build 2>&1
            Write-Host "Build output: $buildOut"
            
            # Check for built files
            if (Test-Path $buildDir) {
                $builtMain = Join-Path $buildDir 'main.js'
                if (Test-Path $builtMain) {
                    Write-Host "Build succeeded! Copying files..."
                    Copy-Item $buildDir "$calDir\build" -Recurse -Force
                    Copy-Item $builtMain $calDir -Force
                    Copy-Item (Join-Path $srcDir 'manifest.json') $calDir -Force
                }
            }
        } catch {
            Write-Host "Build failed: $_"
        }
        Pop-Location
    }
} else {
    Write-Host "No source dir found"
}

Write-Host ""
Write-Host "=== Calendar Plugin Status ==="
Get-ChildItem $calDir -Recurse -File | Where-Object { $_.Name -match '^(main|manifest|styles)' } | ForEach-Object {
    Write-Host "  $($_.Name) ($($_.Length) bytes)"
}

Write-Host ""
Write-Host "=== Enabled Plugins Config ==="
$vault = 'E:\software\Obsidian\vault'
$communityJson = Get-Content (Join-Path $vault '.obsidian\community-plugins.json') -Raw -Encoding UTF8
$enabledJson = Get-Content (Join-Path $vault '.obsidian\enabled-plugins.json') -Raw -Encoding UTF8
Write-Host "community: $communityJson"
Write-Host "enabled: $enabledJson"
