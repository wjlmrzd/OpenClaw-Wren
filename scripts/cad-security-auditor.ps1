# CAD Plugin Security Auditor
# Scans C# source files for common security vulnerabilities
# UTF-8 with BOM encoding

$ErrorActionPreference = "Continue"
$WorkspaceRoot = "D:\OpenClaw\.openclaw\workspace"

# Audit targets
$TargetDirs = @(
    "CadAttrBlockConverter",
    "CadAttrExtractor",
    "CAD_PluginLoader",
    "cad-lsp-manager"
)

# Vulnerability patterns (simple string patterns)
$VulnerabilityPatterns = @{
    "SQL Injection" = @(
        "SqlCommand",
        "ExecuteNonQuery",
        "ExecuteScalar",
        "ExecuteReader",
        "string.Format"
    )
    "Command Injection" = @(
        "Runtime.Exec",
        "ProcessBuilder",
        "System.Diagnostics.Process",
        ".Start(",
        "cmd.exe",
        "powershell.exe"
    )
    "Path Traversal" = @(
        "Path.Combine",
        ".Open(",
        "File.Open",
        "StreamReader",
        "StreamWriter",
        "..\"
    )
    "Sensitive Info Leak" = @(
        "api_key",
        "api-key",
        "password =",
        "Password =",
        "secret =",
        "AKIA",
        "ghp_",
        "ConnectionString"
    )
    "Deserialization" = @(
        "BinaryFormatter",
        "SoapFormatter",
        "NetDataContractSerializer",
        "JavaScriptSerializer",
        "JsonConvert.DeserializeObject",
        "XmlSerializer"
    )
    "XSS/Web Vulnerabilities" = @(
        "innerHTML",
        "document.write",
        ".html(",
        ".append(",
        "Request.",
        "Response.Write"
    )
}

# Results storage
$AuditResults = @{
    ScanTime = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    TotalFilesScanned = 0
    TotalIssuesFound = 0
    Findings = @()
}

function Write-AuditHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Invoke-SecurityScan {
    param(
        [string]$Directory,
        [string]$PatternName,
        [string[]]$Patterns
    )
    
    $results = @()
    $csFiles = Get-ChildItem -Path "$WorkspaceRoot\$Directory" -Filter "*.cs" -Recurse -Force -ErrorAction SilentlyContinue
    
    foreach ($file in $csFiles) {
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($null -eq $content) { continue }
        
        $lineNumber = 0
        $lines = $content -split "`n"
        
        foreach ($line in $lines) {
            $lineNumber++
            $trimmedLine = $line.Trim()
            foreach ($pattern in $Patterns) {
                if ($trimmedLine -match [regex]::Escape($pattern)) {
                    $matchLength = [Math]::Min(80, $trimmedLine.Length)
                    $results += [PSCustomObject]@{
                        File = $file.FullName.Replace($WorkspaceRoot, "")
                        Line = $lineNumber
                        Issue = $PatternName
                        Match = $trimmedLine.Substring(0, $matchLength)
                    }
                    break
                }
            }
        }
    }
    return $results
}

Write-AuditHeader "CAD Plugin Security Audit Report"

# Scan each directory
foreach ($dir in $TargetDirs) {
    if (-not (Test-Path "$WorkspaceRoot\$dir")) {
        Write-Host "[SKIP] Directory not found: $dir" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "`nScanning: $dir" -ForegroundColor Green
    
    $csFiles = Get-ChildItem -Path "$WorkspaceRoot\$dir" -Filter "*.cs" -Recurse -Force -ErrorAction SilentlyContinue
    $AuditResults.TotalFilesScanned += $csFiles.Count
    
    foreach ($category in $VulnerabilityPatterns.Keys) {
        $findings = Invoke-SecurityScan -Directory $dir -PatternName $category -Patterns $VulnerabilityPatterns[$category]
        
        if ($findings.Count -gt 0) {
            Write-Host "  [$category] Found $($findings.Count) potential issue(s)" -ForegroundColor $(if ($category -eq "Sensitive Info Leak") { "Red" } else { "Yellow" })
            
            foreach ($finding in $findings) {
                $AuditResults.Findings += $finding
                $AuditResults.TotalIssuesFound++
                
                $shortPath = $finding.File -replace '\\', '/'
                Write-Host "    $shortPath`:$($finding.Line)" -ForegroundColor DarkGray
                Write-Host "    -> $($finding.Match)" -ForegroundColor DarkYellow
            }
        }
    }
}

# Summary
Write-AuditHeader "Audit Summary"
Write-Host "Scan Time:          $($AuditResults.ScanTime)" -ForegroundColor White
Write-Host "Directories Scanned: $($TargetDirs.Count)" -ForegroundColor White
Write-Host "Files Scanned:      $($AuditResults.TotalFilesScanned)" -ForegroundColor White
Write-Host "Total Issues Found: $($AuditResults.TotalIssuesFound)" -ForegroundColor $(if ($AuditResults.TotalIssuesFound -gt 0) { "Yellow" } else { "Green" })

# Output JSON for programmatic use
$jsonPath = "$WorkspaceRoot\memory\cad-security-audit-latest.json"
$AuditResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding UTF8
Write-Host "`nJSON report saved to: $jsonPath" -ForegroundColor Gray

# Exit code based on findings
if ($AuditResults.TotalIssuesFound -gt 0) {
    Write-Host "`n[!] Security issues detected. Review findings above." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "`n[OK] No critical security issues detected." -ForegroundColor Green
    exit 0
}
