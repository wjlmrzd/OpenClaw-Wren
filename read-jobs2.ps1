# Find the cron state file
$paths = @(
    'D:\OpenClaw\.openclaw\state\openclaw\cron\jobs-state.json',
    'D:\OpenClaw\.openclaw\state\cron-state.json',
    'D:\OpenClaw\.openclaw\cron-state.json'
)
foreach ($p in $paths) {
    if (Test-Path $p) {
        Write-Host "Found: $p"
        Get-Content $p -Raw | Select-Object -First 500
    }
}

# Also list the state directory
Write-Host ""
Write-Host "State directory contents:"
Get-ChildItem 'D:\OpenClaw\.openclaw\state' -Recurse -File -EA SilentlyContinue | Select-Object FullName, Length | Select-Object -First 20
