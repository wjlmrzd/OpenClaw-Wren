$base = 'D:\OpenClaw\.openclaw\workspace\CadAttrBlockConverter'
$dirs = Get-ChildItem $base -Directory
$v5dir = $dirs[6]

$mpPath = Join-Path $v5dir.FullName 'UI\MainPalette.cs'
$mpBytes = [System.IO.File]::ReadAllBytes($mpPath)
$mpContent = [System.Text.Encoding]::UTF8.GetString($mpBytes)
$mpLines = $mpContent -split "`n"

foreach ($line in $mpLines) {
    if ($line -match '^using') {
        $lineBytes = [System.Text.Encoding]::UTF8.GetBytes($line)
        # Check if any replacement char exists
        if ($lineBytes.Length -ne ($line | ForEach-Object { [byte][char]$_ } | Measure-Object).Count) {
            Write-Host "MP REPLACEMENT FOUND: $line"
            Write-Host "MP HEX: " + ([BitConverter]::ToString($lineBytes))
            # Try GB18030
            try {
                $gb = [System.Text.Encoding]::GetEncoding('GB18030')
                $decoded = $gb.GetString($lineBytes)
                Write-Host "MP GB18030: $decoded"
            } catch {}
        }
    }
}

# Also check the full file for the namespace usage in MainPalette
Write-Host "=== SEARCHING FOR NAMESPACE IN MainPalette ==="
$content = [System.IO.File]::ReadAllText($mpPath, [System.Text.Encoding]::UTF8)
# Search for the namespace used in CreateInstance / new statements
if ($content -match 'new\s+(\w+(?:\.\w+)*)\(') {
    Write-Host "NEW statements found"
}
# Look for Logger usage
if ($content -match 'Logger\.') {
    Write-Host "Logger usage found"
}
# Look for CadHost usage
if ($content -match 'CadHost\.') {
    Write-Host "CadHost usage found"
}
