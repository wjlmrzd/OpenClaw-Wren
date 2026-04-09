$ErrorActionPreference = "SilentlyContinue"

# Get last backup
$backups = Get-ChildItem 'D:\OpenClaw\.openclaw\memory\config-backups' | Sort-Object LastWriteTime -Descending
if ($backups) {
    $lastBackup = $backups[0]
    Write-Host "Last backup: $($lastBackup.Name) ($($lastBackup.LastWriteTime))"
    
    # Compare sizes
    $currentSize = (Get-Content 'D:\OpenClaw\.openclaw\openclaw.json' -Raw).Length
    $backupSize = $lastBackup.Length
    Write-Host "Current openclaw.json: $currentSize bytes"
    Write-Host "Backup openclaw.json: $backupSize bytes"
    
    # Get basic field diff
    $current = Get-Content 'D:\OpenClaw\.openclaw\openclaw.json' -Raw | ConvertFrom-Json
    $backupContent = Get-Content $lastBackup.FullName -Raw | ConvertFrom-Json
    Write-Host "Current lastTouchedAt: $($current.lastTouchedAt)"
    Write-Host "Backup lastTouchedAt: $($backupContent.lastTouchedAt)"
    Write-Host "Current logLevel: $($current.logLevel)"
    Write-Host "Backup logLevel: $($backupContent.logLevel)"
    Write-Host "Current agents count: $($current.agents.Count)"
    Write-Host "Backup agents count: $($backupContent.agents.Count)"
    
    # Check if any credentials fields differ
    $currKeys = @()
    if ($current.credentials) { $currKeys = $current.credentials.PSObject.Properties.Name }
    $bkpKeys = @()
    if ($backupContent.credentials) { $bkpKeys = $backupContent.credentials.PSObject.Properties.Name }
    
    Write-Host "Current credentials keys: $($currKeys -join ', ')"
    Write-Host "Backup credentials keys: $($bkpKeys -join ', ')"
    
    # Check for env vars (shouldn't be in JSON)
    if ($current.env) {
        Write-Host "WARNING: env field found in openclaw.json!"
        $envKeys = $current.env.PSObject.Properties.Name
        Write-Host "Env keys: $($envKeys -join ', ')"
    }
} else {
    Write-Host "No backups found"
}

# Git status
Write-Host ""
Write-Host "=== GIT STATUS ==="
Set-Location "D:\OpenClaw\.openclaw"
git status --porcelain 2>&1 | Select-Object -First 20

# Check for sensitive files in git
Write-Host ""
Write-Host "=== SENSITIVE FILES CHECK ==="
$sensitive = @(
    "openclaw.json",
    "credentials",
    ".env",
    "*.json"
)
foreach ($pattern in $sensitive) {
    if ($pattern -eq "credentials") {
        $f = Get-ChildItem "D:\OpenClaw\.openclaw\credentials" -ErrorAction SilentlyContinue
        if ($f) {
            Write-Host "Credentials dir files: $($f.Name -join ', ')"
        }
    }
}

# Cron jobs diff
Write-Host ""
Write-Host "=== CRON JOBS BACKUP DIFF ==="
$cronBackup = Get-ChildItem 'D:\OpenClaw\.openclaw\memory\config-backups' -Filter "jobs-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($cronBackup) {
    $currentCron = Get-Content 'D:\OpenClaw\.openclaw\cron\jobs.json' -Raw | ConvertFrom-Json
    $backupCron = Get-Content $cronBackup.FullName -Raw | ConvertFrom-Json
    Write-Host "Current jobs: $($currentCron.jobs.Count)"
    Write-Host "Backup jobs: $($backupCron.jobs.Count)"
    
    # Find new/removed jobs
    $currIds = $currentCron.jobs.id
    $bkpIds = $backupCron.jobs.id
    $newIds = $currIds | Where-Object { $_ -notin $bkpIds }
    $removedIds = $bkpIds | Where-Object { $_ -notin $currIds }
    if ($newIds) { Write-Host "NEW jobs: $($newIds -join ', ')" }
    if ($removedIds) { Write-Host "REMOVED jobs: $($removedIds -join ', ')" }
    
    # Check for disabled/enabled changes
    foreach ($job in $currentCron.jobs) {
        $backupJob = $backupCron.jobs | Where-Object { $_.id -eq $job.id }
        if ($backupJob -and $backupJob.enabled -ne $job.enabled) {
            Write-Host "STATE CHANGE: $($job.id) [$($job.name)] was $($backupJob.enabled), now $($job.enabled)"
        }
    }
}
