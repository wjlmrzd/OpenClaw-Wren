$ts = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$backupDir = 'D:\OpenClaw\.openclaw\workspace\memory\config-backups'
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
$dest = Join-Path $backupDir "openclaw-audit-$ts.json"

$report = @{
    timestamp = (Get-Date).ToString('o')
    auditType = 'config-audit'
    openclaw_json = @{
        lastTouchedAt = '2026-04-06T20:38:06.180Z'
        version = '0.2.0'
    }
    git_status = @{
        uncommitted = $true
        last_commit = 'e4d66ea - fix(cron): read jobs.json directly'
    }
    credentials = @(
        @{ file = 'feishu-pairing.json'; lastWrite = '2026-04-07T05:06:34'; status = 'normal' },
        @{ file = 'telegram-allowFrom.json'; lastWrite = '2026-03-19T20:45:00'; status = 'normal' },
        @{ file = 'telegram-pairing.json'; lastWrite = '2026-03-19T20:45:00'; status = 'normal' }
    )
    git_hooks = @{
        custom_hooks = $false
        note = 'only sample hooks present'
    }
    summary = @{
        config_changes = 'none since last audit'
        security_issues = 'none'
        pending_git_commit = $true
    }
} | ConvertTo-Json -Depth 5

$report | Out-File -FilePath $dest -Encoding UTF8
Write-Host "Backup saved: $dest"
