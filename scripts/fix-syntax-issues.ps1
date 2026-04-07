# Fix syntax issues in PowerShell scripts
# Strategy:
# 1. Pure markdown docs (.ps1 with only markdown content) -> rename to .md
# 2. Mixed files (real code + markdown) -> extract code sections
# 3. Encoding-corrupted files -> fix encoding
# 4. Real syntax errors -> fix code

$ErrorActionPreference = "SilentlyContinue"
$base = "D:\OpenClaw\.openclaw\workspace\scripts"

$flagged = @(
    'atomic-doc-processor.ps1',
    'atomic-linker.ps1',
    'check-gateway2.ps1',
    'check-urls-health.ps1',
    'check_bookmarks_ps.ps1',
    'daily-digest-generator.ps1',
    'daily-report-generator.ps1',
    'download-plugins.ps1',
    'event-hub-tools.ps1',
    'event-hub.ps1',
    'event-logger.ps1',
    'log-rotate.ps1',
    'notification-coordinator.ps1',
    'notification-gateway-fixed.ps1',
    'pdf-ocr-full.ps1',
    'silence-tools.ps1',
    'system-mode-tools.ps1',
    'telegram-commander.ps1',
    'test-runner-tools.ps1',
    'unified-maintenance-console.ps1',
    'update-model-config.ps1'
)

$results = @()

foreach ($fname in $flagged) {
    $path = Join-Path $base $fname
    if (!(Test-Path $path)) {
        $results += [PSCustomObject]@{ File = $fname; Status = "NOT_FOUND"; Action = "" }
        continue
    }

    $content = Get-Content $path -Raw -Encoding UTF8
    $errors = $null
    [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors)

    # Get first non-comment line that looks like real code
    $lines = $content -split "`n"
    $firstCodeLine = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i].Trim()
        if ($line -and !$line.StartsWith('#') -and !$line.StartsWith('##') -and !$line.StartsWith('```') -and $line.Length -gt 0) {
            $firstCodeLine = $i + 1
            break
        }
    }

    # Check if it's a pure markdown file (no real PowerShell code)
    $hasRealCode = $false
    $psCommands = @('$', 'function', 'param', 'if', 'foreach', 'for', 'while', 'try', 'catch', 'finally', 'switch', 'Get-', 'Set-', 'Write-', 'Invoke-', 'New-', 'Remove-', 'Test-', 'Add-', 'Out-')
    foreach ($line in $lines) {
        foreach ($cmd in $psCommands) {
            if ($line -match $cmd) {
                $hasRealCode = $true
                break
            }
        }
        if ($hasRealCode) { break }
    }

    $firstError = if ($errors.Count -gt 0) { $errors[0] } else { $null }
    $firstErrorLine = if ($firstError) { $firstError.Token.StartLine } else { -1 }

    if (!$hasRealCode) {
        # Pure markdown - rename to .md
        $newPath = $path -replace '\.ps1$', '.md'
        if (Test-Path $newPath) {
            $backupPath = $path -replace '\.ps1$', '.doc-backup.md'
            Move-Item $path $backupPath -Force
            $results += [PSCustomObject]@{ File = $fname; Status = "RENAMED"; Action = "-> .md (backup to .doc-backup.md)" }
        } else {
            Move-Item $path $newPath -Force
            $results += [PSCustomObject]@{ File = $fname; Status = "RENAMED"; Action = "-> .md" }
        }
    } elseif ($firstCodeLine -gt 0 -and $firstErrorLine -gt $firstCodeLine) {
        # Markdown comes before code - extract code (after first real code line)
        # Extract just the code portion (everything from first real code line onward)
        $codeLines = $lines[($firstCodeLine - 1)..($lines.Count - 1)]
        
        # Find code block start and end
        $inBlock = $false
        $cleanLines = @()
        foreach ($line in $codeLines) {
            if ($line.Trim() -eq '```') {
                if ($inBlock) { $inBlock = $false; continue }
                else { $inBlock = $true; continue }
            }
            if (!$inBlock) {
                $cleanLines += $line
            }
        }
        
        $cleanCode = $cleanLines -join "`n"
        
        # Validate cleaned code
        $validateErrors = $null
        [System.Management.Automation.PSParser]::Tokenize($cleanCode, [ref]$validateErrors)
        
        if ($validateErrors.Count -eq 0) {
            # Good - save cleaned code
            Set-Content -Path $path -Value $cleanCode -Encoding UTF8
            $results += [PSCustomObject]@{ File = $fname; Status = "FIXED"; Action = "Extracted code, removed markdown" }
        } else {
            # Still has errors - needs manual fix
            $results += [PSCustomObject]@{ File = $fname; Status = "NEEDS_MANUAL"; Action = "Code still has $($validateErrors.Count) errors after extraction" }
        }
    } else {
        # Code starts immediately or errors before code - check for encoding issues
        $hasEncodingIssue = $false
        foreach ($line in $lines) {
            if ($line -match '[�]') {
                $hasEncodingIssue = $true
                break
            }
        }
        
        if ($hasEncodingIssue) {
            # Try to fix encoding - re-encode with proper UTF-8
            # First, try reading with GBK and converting to UTF-8
            try {
                $gbkContent = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::GetEncoding('GBK'))
                Set-Content -Path $path -Value $gbkContent -Encoding UTF8
                $results += [PSCustomObject]@{ File = $fname; Status = "ENCODING_FIXED"; Action = "Re-encoded from GBK to UTF8" }
            } catch {
                $results += [PSCustomObject]@{ File = $fname; Status = "ENCODING_FAILED"; Action = "Could not fix encoding: $($_.Exception.Message)" }
            }
        } else {
            # Real syntax error
            $results += [PSCustomObject]@{ File = $fname; Status = "NEEDS_MANUAL"; Action = "Real syntax error at line $($firstErrorLine): $($firstError.Message)" }
        }
    }
}

# Summary
Write-Host "=== Fix Summary ==="
$results | Format-Table -AutoSize

$fixed = ($results | Where-Object { $_.Status -match "FIXED|RENAMED|ENCODING_FIXED" }).Count
$manual = ($results | Where-Object { $_.Status -eq "NEEDS_MANUAL" }).Count
Write-Host "Fixed: $fixed / $($results.Count)"
Write-Host "Needs manual: $manual"

$results | ConvertTo-Json -Depth 3 | Out-File "D:\OpenClaw\.openclaw\workspace\memory\syntax-fix-results.json" -Encoding UTF8
