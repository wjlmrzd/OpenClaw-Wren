# Read all important files from the V5.0 directory (index 6 = ??????)
$base = 'D:\OpenClaw\.openclaw\workspace\CadAttrBlockConverter'
$dirs = Get-ChildItem $base -Directory
$v5dir = $dirs[6]
Write-Host "V5 DIR: $($v5dir.Name)"

# Read PluginEntry.cs
$pluginPath = Join-Path $v5dir.FullName 'PluginEntry.cs'
if (Test-Path $pluginPath) {
    $content = [System.IO.File]::ReadAllText($pluginPath, [System.Text.Encoding]::UTF8)
    Write-Host "=== PLUGINENTRY.CS ==="
    Write-Host $content
}

# Read csproj
$csprojPath = Join-Path $v5dir.FullName ($v5dir.Name + '.csproj')
if (Test-Path $csprojPath) {
    $content = [System.IO.File]::ReadAllText($csprojPath, [System.Text.Encoding]::UTF8)
    Write-Host "=== CSPROJ ==="
    Write-Host $content
}

# Read all other files in the directory
Write-Host "=== ALL FILES IN V5 DIR ==="
Get-ChildItem $v5dir.FullName -File | ForEach-Object {
    Write-Host "--- FILE: $($_.Name) ---"
    Write-Host ([System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8))
}
