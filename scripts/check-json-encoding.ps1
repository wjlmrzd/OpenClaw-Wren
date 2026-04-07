# Check JSON files for BOM and encoding issues
param(
    [string]$Path = "D:\OpenClaw\.openclaw\workspace",
    [string]$OutputFile = "D:\OpenClaw\.openclaw\workspace\scripts\json-encoding-report.txt"
)

$results = @()
$allJsonFiles = Get-ChildItem -Path $Path -Recurse -Filter "*.json" -File | Where-Object { $_.FullName -notmatch "node_modules" -and $_.FullName -notmatch "\.git" }

foreach ($file in $allJsonFiles) {
    try {
        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
        $hasBOM = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF

        # Read as UTF8 without BOM
        $content = [System.Text.Encoding]::UTF8.GetString($bytes)
        if ($hasBOM) {
            $content = $content.Substring(1)
        }

        # Try parse
        $parsed = $content | ConvertFrom-Json -ErrorAction SilentlyContinue
        $parseOk = $null -ne $parsed

        # Check first few bytes
        $hexHeader = ($bytes[0..[Math]::Min(5, $bytes.Length-1)] | ForEach-Object { $_.ToString("X2") }) -join " "

        $results += [PSCustomObject]@{
            File = $file.FullName.Replace($Path, "~")
            HasBOM = $hasBOM
            ParseOK = $parseOk
            HexHeader = $hexHeader
            SizeKB = [Math]::Round($file.Length / 1KB, 1)
        }
    } catch {
        $results += [PSCustomObject]@{
            File = $file.FullName.Replace($Path, "~")
            HasBOM = "?"
            ParseOK = $false
            HexHeader = "ERROR: $($_.Exception.Message.Substring(0, [Math]::Min(80, $_.Exception.Message.Length))"
            SizeKB = [Math]::Round($file.Length / 1KB, 1)
        }
    }
}

# Output to file
$output = $results | Sort-Object { $_.ParseOK -eq $false }, HasBOM | Format-Table -AutoSize | Out-String
$output | Out-File -FilePath $OutputFile -Encoding UTF8

# Also fix files that have BOM and are parseable
$toFix = $results | Where-Object { $_.HasBOM -eq $true -and $_.ParseOK -eq $true }
$fixed = @()
foreach ($item in $toFix) {
    $fullPath = $item.File.Replace("~", $Path)
    $bytes = [System.IO.File]::ReadAllBytes($fullPath)
    # Remove UTF8 BOM if present
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $cleanBytes = $bytes[3..($bytes.Length-1)]
        [System.IO.File]::WriteAllBytes($fullPath, $cleanBytes)
        $fixed += $item.File
    }
}

# Also fix files that are parseable but have wrong encoding (not UTF8)
# Check for GBK/Big5 markers
$wrongEncoding = @()
foreach ($file in $allJsonFiles) {
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    if ($bytes.Length -gt 0 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        $wrongEncoding += $file.FullName.Replace($Path, "~")
    }
}

$summary = @"
=== JSON Encoding Report ===
Checked: $($results.Count) files
Files with BOM: $($results | Where-Object { $_.HasBOM -eq $true }).Count
Parseable with BOM: $($results | Where-Object { $_.HasBOM -eq $true -and $_.ParseOK -eq $true }).Count
Parseable without BOM: $($results | Where-Object { $_.HasBOM -eq $false -and $_.ParseOK -eq $true }).Count
UNPARSEABLE: $($results | Where-Object { $_.ParseOK -eq $false }).Count

Fixed (BOM removed): $($fixed.Count)
Wrong encoding (UTF-16 LE): $($wrongEncoding.Count)

=== UNPARSEABLE FILES ===
"@
($results | Where-Object { $_.ParseOK -eq $false } | Format-Table -AutoSize | Out-String) | ForEach-Object { $summary += "`n$_" }

$summary | Out-File -FilePath $OutputFile -Encoding UTF8 -Append

Write-Host $summary
Write-Host "Report saved to: $OutputFile"
if ($fixed.Count -gt 0) {
    Write-Host "Fixed files:"
    $fixed | ForEach-Object { Write-Host "  - $_" }
}
