# Configuration File Integrity Checker
# Generates SHA256 checksums and monitors for unauthorized changes
# UTF-8 with BOM encoding

$ErrorActionPreference = "Continue"
$WorkspaceRoot = "D:\OpenClaw\.openclaw\workspace"
$ChecksumFile = "$WorkspaceRoot\memory\config-checksums.json"

# Target files for integrity monitoring
$TargetFiles = @(
    "$WorkspaceRoot\config\openclaw.json",
    "$WorkspaceRoot\cron\jobs.json",
    "$WorkspaceRoot\.env",
    "$WorkspaceRoot\.env.example"
)

# Credentials files (sensitive)
$CredentialsDir = "$WorkspaceRoot\credentials"
$CredentialPatterns = @("*.json", "*.key", "*.pem", "*.credentials")

function Get-FileChecksum {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        return $null
    }
    
    $hash = Get-FileHash -Path $FilePath -Algorithm SHA256
    $fileInfo = Get-Item -Path $FilePath
    
    return @{
        checksum = "sha256:$($hash.Hash.ToLower())"
        size = $fileInfo.Length
        lastModified = $fileInfo.LastWriteTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
}

function Get-ExistingChecksums {
    if (Test-Path $ChecksumFile) {
        $content = Get-Content -Path $ChecksumFile -Raw -Encoding UTF8
        return $content | ConvertFrom-Json
    }
    return $null
}

function Save-Checksums {
    param($Checksums)
    
    $Checksums | ConvertTo-Json -Depth 5 | Out-File -FilePath $ChecksumFile -Encoding UTF8
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Configuration Integrity Checker" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$existingData = Get-ExistingChecksums
$currentTime = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
$results = @{
    lastChecked = $currentTime
    files = @{}
    alerts = @()
    changes = @()
}

# Check configured target files
Write-Host "Checking configured files..." -ForegroundColor White

foreach ($filePath in $TargetFiles) {
    $fileName = Split-Path -Path $filePath -Leaf
    $checksum = Get-FileChecksum -FilePath $filePath
    
    if ($null -eq $checksum) {
        Write-Host "  [SKIP] File not found: $fileName" -ForegroundColor Yellow
        continue
    }
    
    $results.files[$fileName] = $checksum
    Write-Host "  [OK]   $fileName" -ForegroundColor Green
    Write-Host "        SHA256: $($checksum.checksum)" -ForegroundColor DarkGray
    
    # Compare with existing
    if ($null -ne $existingData -and $existingData.files.$fileName) {
        $oldChecksum = $existingData.files.$fileName.checksum
        if ($oldChecksum -ne $checksum.checksum) {
            Write-Host "        [!] CHANGE DETECTED!" -ForegroundColor Red
            $results.changes += @{
                file = $fileName
                oldChecksum = $oldChecksum
                newChecksum = $checksum.checksum
                oldSize = $existingData.files.$fileName.size
                newSize = $checksum.size
            }
            $results.alerts += "FILE CHANGED: $fileName - checksum mismatch"
        }
    }
}

# Check credentials directory
Write-Host ""
Write-Host "Checking credentials directory..." -ForegroundColor White

if (Test-Path $CredentialsDir) {
    $credFiles = Get-ChildItem -Path $CredentialsDir -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer }
    
    foreach ($file in $credFiles) {
        $fileName = $file.Name
        $checksum = Get-FileChecksum -FilePath $file.FullName
        
        if ($null -ne $checksum) {
            $results.files["credentials/$fileName"] = $checksum
            Write-Host "  [OK]   credentials/$fileName" -ForegroundColor Green
            
            # Compare with existing
            if ($null -ne $existingData -and $existingData.files."credentials/$fileName") {
                $oldChecksum = $existingData.files."credentials/$fileName".checksum
                if ($oldChecksum -ne $checksum.checksum) {
                    Write-Host "        [!] CHANGE DETECTED!" -ForegroundColor Red
                    $results.changes += @{
                        file = "credentials/$fileName"
                        oldChecksum = $oldChecksum
                        newChecksum = $checksum.checksum
                    }
                    $results.alerts += "CREDENTIALS CHANGED: $fileName - unauthorized modification detected"
                }
            }
        }
    }
} else {
    Write-Host "  [SKIP] Credentials directory not found" -ForegroundColor Yellow
}

# Save updated checksums
Save-Checksums -Checksums $results

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Last Checked: $currentTime" -ForegroundColor White
Write-Host "Files Monitored: $($results.files.Count)" -ForegroundColor White
Write-Host "Changes Detected: $($results.changes.Count)" -ForegroundColor $(if ($results.changes.Count -gt 0) { "Yellow" } else { "Green" })
Write-Host "Alerts Generated: $($results.alerts.Count)" -ForegroundColor $(if ($results.alerts.Count -gt 0) { "Red" } else { "Green" })

if ($results.alerts.Count -gt 0) {
    Write-Host ""
    Write-Host "ALERTS:" -ForegroundColor Red
    foreach ($alert in $results.alerts) {
        Write-Host "  - $alert" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Checksums saved to: $ChecksumFile" -ForegroundColor Gray

# Exit code
if ($results.alerts.Count -gt 0) {
    exit 2  # Changes detected
} else {
    exit 0  # No changes
}
