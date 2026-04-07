# Analyze the syntax issues more carefully
$base = "D:\OpenClaw\.openclaw\workspace\scripts"

$issues = @{
    'atomic-doc-processor.ps1' = $null
    'atomic-linker.ps1' = $null
    'check-gateway2.ps1' = $null
    'unified-maintenance-console.ps1' = $null
    'update-model-config.ps1' = $null
    'notification-gateway-fixed.ps1' = $null
}

foreach ($f in $issues.Keys) {
    $path = Join-Path $base $f
    $errors = $null
    $content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors)
    if ($errors.Count -gt 0) {
        Write-Host "=== $f ==="
        $errors | Select-Object -First 3 | ForEach-Object {
            $line = $_.Token.StartLine
            Write-Host "Line $line : $($_.Message)"
            $lineContent = ($content -split "`n")[$line - 1]
            Write-Host "  Content: $lineContent"
        }
        Write-Host ""
    }
    $issues[$f] = $errors
}
