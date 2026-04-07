# disk-space-check.ps1 - Check D drive space usage
# Avoid inline PowerShell commands to prevent encoding issues

$ErrorActionPreference = "SilentlyContinue"

try {
    $d = Get-Volume D
    $total = $d.Size
    $free = $d.SizeRemaining
    $usedPercent = [math]::Round(($total - $free) / $total * 100, 1)
    
    $totalGB = [math]::Round($total / 1GB, 2)
    $freeGB = [math]::Round($free / 1GB, 2)
    $usedGB = [math]::Round(($total - $free) / 1GB, 2)
    
    Write-Output "Drive D: Total ${totalGB}GB | Used ${usedGB}GB (${usedPercent}%) | Free ${freeGB}GB"
    
    if ($usedPercent -gt 85) {
        Write-Output "WARNING: D drive usage exceeds 85%"
    }
    
    if ($usedPercent -gt 95) {
        Write-Output "CRITICAL: D drive usage exceeds 95%, immediate cleanup required"
    }
} catch {
    Write-Output "ERROR: Cannot get D drive info - $_"
}