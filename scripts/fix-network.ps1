$ErrorActionPreference = 'Continue'

# Check proxy settings
Write-Host "=== Proxy Settings ==="
Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' | Select-Object ProxyEnable, ProxyServer | Format-List
[System.Net.WebProxy]::GetDefaultProxy() | Format-List
Write-Host ""

# Test direct connection (bypass proxy)
Write-Host "=== Direct Connection Tests ==="
$testUrls = @(
    "https://www.google.com",
    "https://api.github.com",
    "https://registry.npmjs.org"
)
foreach ($u in $testUrls) {
    try {
        $r = Invoke-WebRequest -Uri $u -TimeoutSec 5 -UseBasicParsing
        Write-Host "OK: $u ($($r.StatusCode))"
    } catch {
        Write-Host "FAIL: $u - $($_.Exception.Message)"
    }
}
