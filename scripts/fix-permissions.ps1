# Fix OpenClaw directory permissions
$dir = "D:\OpenClaw\.openclaw"
$user = $env:USERNAME

Write-Host "Current user: $user"

# Remove inheritance
icacls $dir /inheritance:r
Write-Host "Inheritance removed for $dir"

# Grant full control to current user
icacls $dir /grant:r "${user}:(OI)(CI)F"
Write-Host "Granted full control to $user on $dir"

# Fix openclaw.json
$configFile = "$dir\openclaw.json"
if (Test-Path $configFile) {
    icacls $configFile /inheritance:r
    icacls $configFile /grant:r "${user}:F"
    Write-Host "Fixed permissions on openclaw.json"
}

# Fix credentials directory
$credDir = "$dir\credentials"
if (Test-Path $credDir) {
    icacls $credDir /inheritance:r
    icacls $credDir /grant:r "${user}:(OI)(CI)F"
    Write-Host "Fixed permissions on credentials directory"
}

# Fix auth-profiles.json
$authFile = "$dir\agents\main\agent\auth-profiles.json"
if (Test-Path $authFile) {
    icacls $authFile /inheritance:r
    icacls $authFile /grant:r "${user}:F"
    Write-Host "Fixed permissions on auth-profiles.json"
}

# Fix sessions.json
$sessionFile = "$dir\agents\main\sessions\sessions.json"
if (Test-Path $sessionFile) {
    icacls $sessionFile /inheritance:r
    icacls $sessionFile /grant:r "${user}:F"
    Write-Host "Fixed permissions on sessions.json"
}

Write-Host ""
Write-Host "=== Permission Summary ==="
icacls $dir | Select-Object -First 10
