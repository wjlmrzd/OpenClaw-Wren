$base = 'D:\OpenClaw\.openclaw\workspace\CadAttrBlockConverter'
$dirs = Get-ChildItem $base -Directory
$v5dir = $dirs[6]

# Read raw bytes of the garbled namespace
$bsPath = Join-Path $v5dir.FullName 'Core\BlockSwapper.cs'
$bytes = [System.IO.File]::ReadAllBytes($bsPath)
$content = [System.Text.Encoding]::UTF8.GetString($bytes)

# Find the line with the garbled namespace
$lines = $content -split "`n"
foreach ($line in $lines) {
    if ($line -match 'ɢ' -or $line -match '散' -or $line -match '块' -or $line -match '变' -or $line -match '属' -or $line -match '性' -or $line -match '快') {
        # Find byte positions
        $idx = $content.IndexOf($line)
        $startByte = [System.Text.Encoding]::UTF8.GetByteCount($content.Substring(0, $idx))
        $lineBytes = [System.Text.Encoding]::UTF8.GetBytes($line)
        Write-Host "MATCH: $line"
        Write-Host "BYTE-HEX: " + ([BitConverter]::ToString($lineBytes) -replace '-', ' ')
        
        # Try GB18030 decode
        try {
            $gb = [System.Text.Encoding]::GetEncoding('GB18030')
            $decoded = $gb.GetString($lineBytes)
            Write-Host "GB18030: $decoded"
        } catch {}
        
        # Try Big5
        try {
            $big5 = [System.Text.Encoding]::GetEncoding('Big5')
            $decoded = $big5.GetString($lineBytes)
            Write-Host "BIG5: $decoded"
        } catch {}
    }
}

# For MainPalette.cs
$mpPath = Join-Path $v5dir.FullName 'UI\MainPalette.cs'
$mpBytes = [System.IO.File]::ReadAllBytes($mpPath)
$mpContent = [System.Text.Encoding]::UTF8.GetString($mpBytes)
$mpLines = $mpContent -split "`n"
foreach ($line in $mpLines) {
    if ($line -match '^\s*using\s+\?' -or $line -match '^\s*using\s+ɢ') {
        $lineBytes = [System.Text.Encoding]::UTF8.GetBytes($line)
        Write-Host "MP MATCH: $line"
        Write-Host "MP BYTE-HEX: " + ([BitConverter]::ToString($lineBytes) -replace '-', ' ')
        
        # Try GB18030
        try {
            $gb = [System.Text.Encoding]::GetEncoding('GB18030')
            $decoded = $gb.GetString($lineBytes)
            Write-Host "GB18030: $decoded"
        } catch {}
    }
}
