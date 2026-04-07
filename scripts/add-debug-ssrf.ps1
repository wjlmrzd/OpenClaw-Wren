$path = "C:\Users\Administrator\AppData\Roaming\npm\node_modules\openclaw-cn\dist\infra\net\ssrf.js"
$content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

$old = @'
    const isExplicitAllowed = allowedHostnames.has(normalized);
'@

$new = @'
    const isExplicitAllowed = allowedHostnames.has(normalized);
    if (hostname === "api.telegram.org" || hostname.includes("api.telegram.org")) {
        console.error(`[DEBUG-SSRF] api.telegram.org check: normalized="${normalized}" isExplicitAllowed=${isExplicitAllowed} allowPrivateNetwork=${allowPrivateNetwork} hostnameAllowlist.length=${hostnameAllowlist.length}`);
    }
'@

if ($content.Contains($old)) {
    $content = $content.Replace($old, $new)
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "DEBUG added"
} else {
    Write-Host "Pattern not found"
}
