$base = 'D:\OpenClaw\.openclaw\workspace\CadAttrBlockConverter'
$dirs = Get-ChildItem $base -Directory
$v5dir = $dirs[6]

$bsPath = Join-Path $v5dir.FullName 'Core\BlockSwapper.cs'
$bytes = [System.IO.File]::ReadAllBytes($bsPath)
$content = [System.Text.Encoding]::UTF8.GetString($bytes)
$lines = $content -split "`n"

foreach ($line in $lines) {
    if ($line -match '^using') {
        # Check if line has non-ASCII Chinese characters
        $hasChinese = $false
        for ($i = 0; $i -lt $line.Length; $i++) {
            $c = $line[$i]
            if ([int]$c -gt 0x4E00 -and [int]$c -lt 0x9FFF) {
                $hasChinese = $true; break
            }
            if ([int]$c -gt 0x3000 -and [int]$c -lt 0x4E00) {
                $hasChinese = $true; break
            }
        }
        if ($hasChinese -or $line -match '\?[^\w\s]') {
            $lineBytes = [System.Text.Encoding]::UTF8.GetBytes($line)
            Write-Host "FOUND: $line"
            Write-Host "LEN: $($line.Length) CHARS, $($lineBytes.Length) BYTES"
            Write-Host "HEX: " + ([BitConverter]::ToString($lineBytes))
            
            # Try GB18030
            try {
                $gb = [System.Text.Encoding]::GetEncoding('GB18030')
                $decoded = $gb.GetString($lineBytes)
                Write-Host "GB18030: $decoded"
            } catch { Write-Host "GB18030 FAILED" }
        }
    }
}

Write-Host "==="
$mpPath = Join-Path $v5dir.FullName 'UI\MainPalette.cs'
$mpBytes = [System.IO.File]::ReadAllBytes($mpPath)
$mpContent = [System.Text.Encoding]::UTF8.GetString($mpBytes)
$mpLines = $mpContent -split "`n"
foreach ($line in $mpLines) {
    if ($line -match '^using') {
        $hasProblem = $false
        for ($i = 0; $i -lt $line.Length; $i++) {
            $c = $line[$i]
            $code = [int]$c
            if ($code -eq 0xFFFD -or $code -gt 0x4E00 -and $code -lt 0x9FFF) {
                $hasProblem = $true; break
            }
        }
        if ($hasProblem) {
            $lineBytes = [System.Text.Encoding]::UTF8.GetBytes($line)
            Write-Host "MP FOUND: $line"
            Write-Host "MP HEX: " + ([BitConverter]::ToString($lineBytes))
            try {
                $gb = [System.Text.Encoding]::GetEncoding('GB18030')
                $decoded = $gb.GetString($lineBytes)
                Write-Host "MP GB18030: $decoded"
            } catch {}
        }
    }
}
