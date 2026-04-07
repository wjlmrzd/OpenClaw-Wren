[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = "D:\OpenClaw\.openclaw\workspace\memory\config-backups"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

# Snapshot openclaw.json
$config = Get-Content "D:\OpenClaw\.openclaw\workspace\openclaw.json" -Encoding UTF8 | ConvertFrom-Json
$meta = @{
    lastTouchedAt = $config.meta.lastTouchedAt
    lastTouchedVersion = $config.meta.lastTouchedVersion
    wizard_lastRunAt = $config.wizard.lastRunAt
    snapshotTime = (Get-Date).ToString("o")
}
$meta | ConvertTo-Json | Set-Content "$backupDir\openclaw-meta-$ts.json"

# Snapshot cron jobs count + IDs
$jobs = Get-Content "D:\OpenClaw\.openclaw\workspace\cron\jobs.json" -Encoding UTF8 | ConvertFrom-Json
$jobSummary = @{
    totalJobs = $jobs.jobs.Count
    enabledJobs = ($jobs.jobs | Where-Object { $_.enabled }).Count
    jobIds = ($jobs.jobs | ForEach-Object { $_.id }) -join ","
    snapshotTime = (Get-Date).ToString("o")
}
$jobSummary | ConvertTo-Json | Set-Content "$backupDir\cron-meta-$ts.json"

# Credential files snapshot
$credFiles = @()
Get-ChildItem "D:\OpenClaw\.openclaw\credentials" | ForEach-Object {
    $acl = Get-Acl $_.FullName
    $credFiles += @{
        name = $_.Name
        length = $_.Length
        owner = $acl.Owner
        lastWrite = $_.LastWriteTime.ToString("o")
        hasSensitive = $false
    }
}
$credSummary = @{
    files = $credFiles
    snapshotTime = (Get-Date).ToString("o")
}
$credSummary | ConvertTo-Json | Set-Content "$backupDir\credentials-meta-$ts.json"

# Git status summary
Set-Location "D:\OpenClaw\.openclaw\workspace"
$gitStatus = ""
try {
    $gitStatus = git status --porcelain 2>$null
} catch {}

$modified = ($gitStatus -match "^ M") -replace "^ M\s+", ""
$deleted = ($gitStatus -match "^ D") -replace "^ D\s+", ""
$untracked = ($gitStatus -match "^\?\?") -replace "^\?\?\s+", ""

$gitSummary = @{
    modifiedFiles = ($modified -split "`n" | Where-Object { $_ -ne "" })
    deletedFiles = ($deleted -split "`n" | Where-Object { $_ -ne "" })
    untrackedCount = (($untracked -split "`n" | Where-Object { $_ -ne "" }).Count)
    sensitiveExposed = $false
    snapshotTime = (Get-Date).ToString("o")
}
$gitSummary | ConvertTo-Json -Depth 5 | Set-Content "$backupDir\git-meta-$ts.json"

Write-Output "Backup snapshot created: $ts"
Write-Output "Files: openclaw-meta-$ts.json, cron-meta-$ts.json, credentials-meta-$ts.json, git-meta-$ts.json"
