$base = 'D:\OpenClaw\.openclaw\workspace\CadAttrBlockConverter'
$dirs = Get-ChildItem $base -Directory
$v5dir = $dirs[6]

# Read the raw bytes of BlockSwapper.cs to find the garbled namespace
$bsPath = Join-Path $v5dir.FullName 'Core\BlockSwapper.cs'
$bytes = [System.IO.File]::ReadAllBytes($bsPath)
$content = [System.Text.Encoding]::UTF8.GetString($bytes)

# Find the using statement with the garbled namespace
$lines = $content -split "`n"
foreach ($line in $lines) {
    if ($line -match 'using\s+\w' -and $line -notmatch 'Autodesk|AutoCAD|System|Material|CadAttr') {
        Write-Host "GARBLED USING: $line"
    }
}

# Also check MainPalette.cs
$mpPath = Join-Path $v5dir.FullName 'UI\MainPalette.cs'
$bytes2 = [System.IO.File]::ReadAllBytes($mpPath)
$content2 = [System.Text.Encoding]::UTF8.GetString($bytes2)
$lines2 = $content2 -split "`n"
foreach ($line in $lines2) {
    if ($line -match 'using\s+\w' -and $line -notmatch 'Autodesk|AutoCAD|System|Material|CadAttr') {
        Write-Host "GARBLED USING MP: $line"
    }
}

# Also check PluginEntry.cs
$pePath = Join-Path $v5dir.FullName 'PluginEntry.cs'
$bytes3 = [System.IO.File]::ReadAllBytes($pePath)
$content3 = [System.Text.Encoding]::UTF8.GetString($bytes3)
$lines3 = $content3 -split "`n"
foreach ($line in $lines3) {
    if ($line -match 'using\s+\w' -and $line -notmatch 'Autodesk|AutoCAD|System|Material|CadAttr') {
        Write-Host "GARBLED USING PE: $line"
    }
}

# Print full namespace section
Write-Host "=== FULL USING SECTION (BlockSwapper) ==="
$inUsing = $false
foreach ($line in $lines) {
    if ($line -match '^using\s+') { $inUsing = $true }
    if ($inUsing) { Write-Host $line }
    if ($inUsing -and $line -match '^\s*$') { $inUsing = $false; break }
}

Write-Host "=== FULL USING SECTION (MainPalette) ==="
$inUsing = $false
foreach ($line in $lines2) {
    if ($line -match '^using\s+') { $inUsing = $true }
    if ($inUsing) { Write-Host $line }
    if ($inUsing -and $line -match '^\s*$') { $inUsing = $false; break }
}
