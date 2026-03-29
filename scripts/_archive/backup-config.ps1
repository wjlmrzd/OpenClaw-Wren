# Disaster Recovery Backup Script
$timestamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$backupDir = "D:\OpenClaw\.openclaw\workspace\memory\disaster-recovery"

# Create backup directory
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

# Backup openclaw.json
Copy-Item "D:\OpenClaw\.openclaw\openclaw.json" -Destination "$backupDir\openclaw-$timestamp.json" -Force

# Backup cron/jobs.json
Copy-Item "D:\OpenClaw\.openclaw\cron\jobs.json" -Destination "$backupDir\cron-jobs-$timestamp.json" -Force

# Backup credentials
$credBackupDir = "$backupDir\credentials-$timestamp"
New-Item -ItemType Directory -Force -Path $credBackupDir | Out-Null
if (Test-Path "D:\OpenClaw\.openclaw\credentials") {
    Copy-Item "D:\OpenClaw\.openclaw\credentials\*" -Destination $credBackupDir -Recurse -Force
}

Write-Host "Backup created: $timestamp"
Write-Host "Files backed up:"
Get-ChildItem $backupDir -Filter "*$timestamp*" -Recurse | ForEach-Object { Write-Host "  $($_.FullName)" }