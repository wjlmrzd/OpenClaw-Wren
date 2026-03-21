# Secure Token Storage for OpenClaw
# Uses Windows Data Protection API (DPAPI)

param(
    [Parameter(Mandatory=$false)]
    [switch]$Init,
    
    [Parameter(Mandatory=$false)]
    [switch]$Load
)

# Load required assembly for DPAPI
Add-Type -AssemblyName System.Security

$SecureDir = "$env:USERPROFILE\.openclaw\secure"
$TokenFile = "$SecureDir\tokens.enc"

function Initialize-SecureStorage {
    if (!(Test-Path $SecureDir)) {
        New-Item -ItemType Directory -Path $SecureDir -Force | Out-Null
    }
    
    $tokens = @{
        TELEGRAM_BOT_TOKEN = '8329757047:AAEas5LRhvSSGBY6t0zsHzyV8nv_8CZyczA'
        TELEGRAM_CHAT_ID = '8542040756'
        BRAVE_SEARCH_API_KEY = 'BSAEro5vT9VIpyMlkPxaYKqTbWqNVhU'
        GATEWAY_AUTH_TOKEN = ''
        GITHUB_TOKEN = ''
    }
    
    $json = $tokens | ConvertTo-Json -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $encrypted = [System.Security.Cryptography.ProtectedData]::Protect(
        $bytes, 
        $null, 
        [System.Security.Cryptography.DataProtectionScope]::CurrentUser
    )
    
    [System.IO.File]::WriteAllBytes($TokenFile, $encrypted)
    Write-Host "Secure storage initialized at: $TokenFile"
    Write-Host "Tokens are encrypted with your Windows user account"
}

function Load-SecureStorage {
    if (!(Test-Path $TokenFile)) {
        Write-Error "Secure storage not found. Run with -Init first."
        return
    }
    
    $encrypted = [System.IO.File]::ReadAllBytes($TokenFile)
    $bytes = [System.Security.Cryptography.ProtectedData]::Unprotect(
        $encrypted,
        $null,
        [System.Security.Cryptography.DataProtectionScope]::CurrentUser
    )
    
    $json = [System.Text.Encoding]::UTF8.GetString($bytes)
    $tokens = $json | ConvertFrom-Json
    
    # Output as environment variable SET commands
    $tokens.PSObject.Properties | ForEach-Object {
        Write-Output "SET $($_.Name)=$($_.Value)"
    }
}

if ($Init) {
    Initialize-SecureStorage
} elseif ($Load) {
    Load-SecureStorage
} else {
    Write-Host "Usage:"
    Write-Host "  .\secure-storage.ps1 -Init    # Initialize secure storage"
    Write-Host "  .\secure-storage.ps1 -Load    # Load tokens (outputs SET commands)"
}
