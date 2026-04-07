# MiniMax Token Plan Query Script
$ErrorActionPreference = "Stop"

$envFile = "$PSScriptRoot\..\.env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            $name = $Matches[1].Trim()
            $value = $Matches[2].Trim()
            if (-not [Environment]::GetEnvironmentVariable($name)) {
                [Environment]::SetEnvironmentVariable($name, $value, "Process")
            }
        }
    }
}

$apiKey = $env:MINIMAX_API
if (-not $apiKey) {
    Write-Error "MINIMAX_API not set"
    exit 1
}

$url = "https://www.minimaxi.com/v1/api/openplatform/coding_plan/remains"
$headers = @{
    "Authorization" = "Bearer $apiKey"
    "Content-Type" = "application/json"
}

try {
    Write-Host "Querying MiniMax Token Plan usage..." -ForegroundColor Cyan
    $response = Invoke-RestMethod -Uri $url -Method POST -Headers $headers -ContentType "application/json" -TimeoutSec 30
    
    Write-Host "`n========== MiniMax Token Plan ==========" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 5
    
    return $response
} catch {
    Write-Error "Query failed: $_"
    exit 1
}
