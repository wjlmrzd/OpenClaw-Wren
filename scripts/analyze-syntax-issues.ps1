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

$issues = @()

foreach ($f in $flagged) {
    $path = Join-Path $base $f
    if (Test-Path $path) {
        $errors = $null
        $content = Get-Content $path -Raw
        $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors)
        if ($errors.Count -gt 0) {
            $first = $errors[0]
            $issues += [PSCustomObject]@{
                File = $f
                Count = $errors.Count
                Line = $first.Token.StartLine
                Col = $first.Token.StartColumn
                Message = $first.Message
            }
            Write-Host "$f : $($errors.Count) issue(s) - Line $($first.Token.StartLine): $($first.Message)"
        }
    }
}

Write-Host ""
Write-Host "Total: $($issues.Count) files"
$issues | ConvertTo-Json -Depth 3 | Out-File "D:\OpenClaw\.openclaw\workspace\memory\syntax-issues.json" -Encoding UTF8
