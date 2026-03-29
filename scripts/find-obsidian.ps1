# Check if Obsidian is installed
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$obsidianPaths = @(
    'E:\software\Obsidian\Obsidian.exe',
    'E:\software\Obsidian\Obsidian Portal\Obsidian.exe',
    "${env:ProgramFiles}\Obsidian\Obsidian.exe",
    "${env:LOCALAPPDATA}\Obsidian\Obsidian.exe"
)

Write-Host "Searching for Obsidian executable..."
$found = $false
foreach ($p in $obsidianPaths) {
    if (Test-Path $p) {
        Write-Host "Found: $p"
        $found = $true
    }
}

if (-not $found) {
    Write-Host "Obsidian executable not found in standard locations"
}

# Check vault .obsidian directory
$vault = 'E:\software\Obsidian\vault'
$obsidianDir = Join-Path $vault '.obsidian'
$pluginsDir = Join-Path $obsidianDir 'plugins'

Write-Host ""
Write-Host "Vault: $vault"
Write-Host ".obsidian dir exists: $(Test-Path $obsidianDir)"
Write-Host "plugins dir exists: $(Test-Path $pluginsDir)"

if (Test-Path $obsidianDir) {
    Write-Host ""
    Write-Host ".obsidian contents:"
    Get-ChildItem $obsidianDir | ForEach-Object { Write-Host "  $($_.Name)" }
}
