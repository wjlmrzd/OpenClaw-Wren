$base = 'D:\OpenClaw\.openclaw\workspace\CadAttrBlockConverter'
$dirs = Get-ChildItem $base -Directory
$v5dir = $dirs[6]
Write-Host "V5 DIR: $($v5dir.Name)"

# Core files
$coreDir = Join-Path $v5dir.FullName 'Core'
if (Test-Path $coreDir) {
    Get-ChildItem $coreDir -File | ForEach-Object {
        Write-Host "=== FILE: $($_.Name) ==="
        Write-Host ([System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8))
        Write-Host ""
    }
}

# Common files
$commonDir = Join-Path $v5dir.FullName 'Common'
if (Test-Path $commonDir) {
    Get-ChildItem $commonDir -File | ForEach-Object {
        Write-Host "=== FILE: $($_.Name) ==="
        Write-Host ([System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8))
        Write-Host ""
    }
}

# UI files
$uiDir = Join-Path $v5dir.FullName 'UI'
if (Test-Path $uiDir) {
    Get-ChildItem $uiDir -File | ForEach-Object {
        Write-Host "=== FILE: $($_.Name) ==="
        Write-Host ([System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8))
        Write-Host ""
    }
}
