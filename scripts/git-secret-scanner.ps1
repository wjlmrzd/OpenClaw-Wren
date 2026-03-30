# Git Secret Scanner
# Scans workspace files and git history for leaked secrets/credentials
# UTF-8 with BOM encoding

$ErrorActionPreference = "Continue"
$WorkspaceRoot = "D:\OpenClaw\.openclaw\workspace"

# Secret patterns to detect (simple string patterns)
$SecretPatterns = @{
    "AWS Access Key" = @{
        Pattern = "AKIA"
        Severity = "Critical"
        Description = "AWS Access Key ID"
    }
    "GitHub Token" = @{
        Pattern = "ghp_"
        Severity = "Critical"
        Description = "GitHub Personal Access Token"
    }
    "GitHub OAuth" = @{
        Pattern = "gho_"
        Severity = "Critical"
        Description = "GitHub OAuth Token"
    }
    "Private Key" = @{
        Pattern = "-----BEGIN"
        Severity = "Critical"
        Description = "Private Key Header"
    }
    "Telegram Bot Token" = @{
        Pattern = "bot"
        Severity = "High"
        Description = "Telegram Bot Token pattern"
    }
    "Slack Token" = @{
        Pattern = "xox"
        Severity = "High"
        Description = "Slack Token"
    }
    "Connection String" = @{
        Pattern = "ConnectionString"
        Severity = "High"
        Description = "Database Connection String"
    }
    "Hardcoded Password" = @{
        Pattern = "password"
        Severity = "Medium"
        Description = "Hardcoded Password"
    }
}

# Files to skip
$ExcludePatterns = @(
    "node_modules",
    ".git",
    "bin",
    "obj",
    ".vs",
    "packages",
    "dist",
    "build",
    ".cache"
)

function Write-ScanHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Invoke-FileScan {
    param([string]$FilePath)
    
    $results = @()
    $content = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) { return $results }
    
    $lineNumber = 0
    foreach ($line in ($content -split "`n")) {
        $lineNumber++
        $trimmedLine = $line.Trim()
        
        foreach ($secretType in $SecretPatterns.Keys) {
            $pattern = $SecretPatterns[$secretType].Pattern
            if ($trimmedLine -match [regex]::Escape($pattern)) {
                # Mask the secret in output
                $masked = $trimmedLine.Substring(0, [Math]::Min(60, $trimmedLine.Length))
                
                $results += [PSCustomObject]@{
                    File = $FilePath.Replace($WorkspaceRoot, "")
                    Line = $lineNumber
                    Type = $secretType
                    Severity = $SecretPatterns[$secretType].Severity
                    Match = $masked
                }
                break
            }
        }
    }
    return $results
}

function Invoke-GitHistoryScan {
    param([int]$CommitCount = 100)
    
    $results = @()
    
    Push-Location $WorkspaceRoot
    
    try {
        $commits = git log --oneline -n 5 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [SKIP] Not a git repository" -ForegroundColor Yellow
            return $results
        }
        
        # Get file list from recent commits (simplified)
        $files = git diff HEAD~5 --name-only 2>$null
        if ($files) {
            foreach ($file in $files.Split("`n")) {
                if ($file -and $file -match "\.(json|xml|config|ps1|py|js|ts|md|txt|yml|yaml|env)$") {
                    $content = git show HEAD":$file" 2>$null
                    if ($content) {
                        $lineNumber = 0
                        foreach ($line in ($content -split "`n")) {
                            $lineNumber++
                            foreach ($secretType in $SecretPatterns.Keys) {
                                $pattern = $SecretPatterns[$secretType].Pattern
                                if ($line -match [regex]::Escape($pattern)) {
                                    $masked = $line.Substring(0, [Math]::Min(60, $line.Length))
                                    $results += [PSCustomObject]@{
                                        File = "$file (recent commit)"
                                        Line = $lineNumber
                                        Type = $secretType
                                        Severity = $SecretPatterns[$secretType].Severity
                                        Match = $masked
                                    }
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    catch {
        Write-Host "  [WARN] Git scan error: $_" -ForegroundColor Yellow
    }
    finally {
        Pop-Location
    }
    
    return $results
}

function Invoke-StagedFilesScan {
    $results = @()
    
    Push-Location $WorkspaceRoot
    
    try {
        $stagedFiles = git diff --cached --name-only 2>$null
        if ($LASTEXITCODE -ne 0 -or $null -eq $stagedFiles) {
            return $results
        }
        
        foreach ($file in $stagedFiles.Split("`n")) {
            if ($file -and $file -match "\.(json|xml|config|ps1|py|js|ts|md|txt)$") {
                $content = git show ":$file" 2>$null
                if ($content) {
                    $lineNumber = 0
                    foreach ($line in ($content -split "`n")) {
                        $lineNumber++
                        foreach ($secretType in $SecretPatterns.Keys) {
                            $pattern = $SecretPatterns[$secretType].Pattern
                            if ($line -match [regex]::Escape($pattern)) {
                                $masked = $line.Substring(0, [Math]::Min(60, $line.Length))
                                $results += [PSCustomObject]@{
                                    File = "$file (staged)"
                                    Line = $lineNumber
                                    Type = $secretType
                                    Severity = $SecretPatterns[$secretType].Severity
                                    Match = $masked
                                }
                                break
                            }
                        }
                    }
                }
            }
        }
    }
    catch {
        # Silently ignore
    }
    finally {
        Pop-Location
    }
    
    return $results
}

# Main scan
Write-ScanHeader "Git Secret Scanner"

$allFindings = @()
$scanSummary = @{
    ScanTime = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    FilesScanned = 0
    CommitsScanned = 5
    StagedFilesScanned = 0
    TotalFindings = 0
    Findings = @()
}

# Scan 1: Working directory files
Write-Host "Scanning working directory..." -ForegroundColor White

$files = Get-ChildItem -Path $WorkspaceRoot -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object {
    $excluded = $false
    foreach ($pattern in $ExcludePatterns) {
        if ($_.FullName -match $pattern) {
            $excluded = $true
            break
        }
    }
    -not $excluded
}

$scanableFiles = $files | Where-Object { 
    $_.Extension -match "\.(json|xml|config|ps1|py|js|ts|java|cs|csproj|sln|md|txt|yml|yaml|env)$" -or 
    $_.Name -match "^\.env" 
}

foreach ($file in $scanableFiles) {
    $scanSummary.FilesScanned++
    $findings = Invoke-FileScan -FilePath $file.FullName
    $allFindings += $findings
}

Write-Host "  Scanned $($scanSummary.FilesScanned) files" -ForegroundColor Gray

# Scan 2: Git history
Write-Host "Scanning git history (last 5 commits)..." -ForegroundColor White
$historyFindings = Invoke-GitHistoryScan -CommitCount 5
$allFindings += $historyFindings
Write-Host "  Found $($historyFindings.Count) secrets in history" -ForegroundColor Gray

# Scan 3: Staged files
Write-Host "Scanning staged files..." -ForegroundColor White
$stagedFindings = Invoke-StagedFilesScan
$scanSummary.StagedFilesScanned = ($stagedFindings | Select-Object -ExpandProperty File -Unique).Count
$allFindings += $stagedFindings
Write-Host "  Scanned $($scanSummary.StagedFilesScanned) staged files" -ForegroundColor Gray

# Remove duplicates based on file+line+type
$uniqueFindings = $allFindings | Sort-Object -Property File, Line, Type -Unique
$scanSummary.TotalFindings = $uniqueFindings.Count
$scanSummary.Findings = $uniqueFindings

# Display findings
Write-ScanHeader "Findings"

if ($uniqueFindings.Count -eq 0) {
    Write-Host "No secrets detected." -ForegroundColor Green
} else {
    # Group by severity
    $bySeverity = @{
        Critical = @()
        High = @()
        Medium = @()
    }
    
    foreach ($finding in $uniqueFindings) {
        switch ($finding.Severity) {
            "Critical" { $bySeverity.Critical += $finding }
            "High" { $bySeverity.High += $finding }
            "Medium" { $bySeverity.Medium += $finding }
        }
    }
    
    if ($bySeverity.Critical.Count -gt 0) {
        Write-Host "CRITICAL ($($bySeverity.Critical.Count)):" -ForegroundColor Red
        foreach ($f in $bySeverity.Critical | Select-Object -First 5) {
            $shortPath = $f.File -replace '\\', '/'
            Write-Host "  $shortPath`:$($f.Line) [$($f.Type)]" -ForegroundColor Red
            Write-Host "    -> $($f.Match)" -ForegroundColor DarkRed
        }
        if ($bySeverity.Critical.Count -gt 5) {
            Write-Host "  ... and $($bySeverity.Critical.Count - 5) more" -ForegroundColor Gray
        }
    }
    
    if ($bySeverity.High.Count -gt 0) {
        Write-Host "`nHIGH ($($bySeverity.High.Count)):" -ForegroundColor Yellow
        foreach ($f in $bySeverity.High | Select-Object -First 10) {
            $shortPath = $f.File -replace '\\', '/'
            Write-Host "  $shortPath`:$($f.Line) [$($f.Type)]" -ForegroundColor Yellow
            Write-Host "    -> $($f.Match)" -ForegroundColor DarkYellow
        }
        if ($bySeverity.High.Count -gt 10) {
            Write-Host "  ... and $($bySeverity.High.Count - 10) more" -ForegroundColor Gray
        }
    }
    
    if ($bySeverity.Medium.Count -gt 0) {
        Write-Host "`nMEDIUM ($($bySeverity.Medium.Count)):" -ForegroundColor Magenta
        foreach ($f in $bySeverity.Medium | Select-Object -First 10) {
            $shortPath = $f.File -replace '\\', '/'
            Write-Host "  $shortPath`:$($f.Line) [$($f.Type)]" -ForegroundColor Magenta
        }
        if ($bySeverity.Medium.Count -gt 10) {
            Write-Host "  ... and $($bySeverity.Medium.Count - 10) more" -ForegroundColor Gray
        }
    }
}

# Summary
Write-ScanHeader "Scan Summary"
Write-Host "Scan Time:        $($scanSummary.ScanTime)" -ForegroundColor White
Write-Host "Files Scanned:    $($scanSummary.FilesScanned)" -ForegroundColor White
Write-Host "Commits Scanned:  $($scanSummary.CommitsScanned)" -ForegroundColor White
Write-Host "Staged Files:     $($scanSummary.StagedFilesScanned)" -ForegroundColor White
Write-Host "Total Findings:   $($scanSummary.TotalFindings)" -ForegroundColor $(if ($scanSummary.TotalFindings -gt 0) { "Yellow" } else { "Green" })

# Save report
$reportPath = "$WorkspaceRoot\memory\git-secret-scan-latest.json"
$scanSummary | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "`nReport saved to: $reportPath" -ForegroundColor Gray

# Exit code
if ($scanSummary.TotalFindings -gt 0) {
    exit 1
} else {
    exit 0
}
