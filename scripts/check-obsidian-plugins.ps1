$pluginDir = 'E:\software\Obsidian\vault\.obsidian\plugins'
if (Test-Path $pluginDir) {
    Get-ChildItem $pluginDir -Directory | ForEach-Object {
        Write-Host $_.Name
    }
} else {
    Write-Host 'No plugins directory found'
}

Write-Host ''
Write-Host '=== Community plugins manifest ==='
$manifest = Join-Path $pluginDir 'community-plugins.json'
if (Test-Path $manifest) {
    Get-Content $manifest | ForEach-Object { Write-Host $_ }
}
