$ErrorActionPreference = "SilentlyContinue"
$files = @(
    'D:\OpenClaw\.openclaw\workspace\scripts\check-gateway2.ps1',
    'D:\OpenClaw\.openclaw\workspace\scripts\daily-digest-generator.ps1',
    'D:\OpenClaw\.openclaw\workspace\scripts\update-model-config.ps1'
)

foreach ($f in $files) {
    $content = Get-Content $f -Raw -Encoding UTF8
    $errors = $null
    [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors)
    Write-Host "=== $f ==="
    Write-Host "Size: $($content.Length) chars"
    if ($errors.Count -gt 0) {
        $errors | Select-Object -First 5 | ForEach-Object {
            Write-Host "  Line $($_.Token.StartLine): $($_.Message)"
        }
    } else {
        Write-Host "  No errors"
    }
    Write-Host ""
}
