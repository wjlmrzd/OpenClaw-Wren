# Secure Configuration Manager for OpenClaw
# Stores sensitive data encrypted

$ConfigDir = "$env:USERPROFILE\.openclaw\secure"
$ConfigFile = "$ConfigDir\config.encrypted"

function Ensure-SecureDir {
    if (!(Test-Path $ConfigDir)) {
        New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
        # Restrict permissions
        $acl = Get-Acl $ConfigDir
        $acl.SetAccessRuleProtection($true, $false)
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $env:USERNAME, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
        )
        $acl.AddAccessRule($rule)
        Set-Acl $ConfigDir $acl
    }
}

function Save-SecureConfig($data) {
    Ensure-SecureDir
    $json = $data | ConvertTo-Json -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $encrypted = [System.Security.Cryptography.ProtectedData]::Protect(
        $bytes, 
        $null, 
        [System.Security.Cryptography.DataProtectionScope]::CurrentUser
    )
    [System.IO.File]::WriteAllBytes($ConfigFile, $encrypted)
    Write-Host "Configuration saved securely"
}

function Load-SecureConfig {
    if (!(Test-Path $ConfigFile)) {
        return $null
    }
    $encrypted = [System.IO.File]::ReadAllBytes($ConfigFile)
    $bytes = [System.Security.Cryptography.ProtectedData]::Unprotect(
        $encrypted,
        $null,
        [System.Security.Cryptography.DataProtectionScope]::CurrentUser
    )
    $json = [System.Text.Encoding]::UTF8.GetString($bytes)
    return $json | ConvertFrom-Json
}

function Initialize-Config {
    $config = @{
        TELEGRAM_BOT_TOKEN = "8329757047:AAFxkpIJqkm-8HT1ZFz005tjFDeRRRIisH0"
        TELEGRAM_CHAT_ID = "8542040756"
        BRAVE_SEARCH_API_KEY = "BSAD9CpbQ_U660f8h-uoXk2cJJ1gdbQ"
        GATEWAY_AUTH_TOKEN = ""
        GITHUB_TOKEN = ""
    }
    Save-SecureConfig $config
    return $config
}

# Export functions for use in other scripts
Export-ModuleMember -Function Save-SecureConfig, Load-SecureConfig, Initialize-Config
