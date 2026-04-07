# Fix cron jobs with wrong script references
$jobsPath = "D:\OpenClaw\.openclaw\cron\jobs.json"
$jobs = Get-Content $jobsPath -Raw -Encoding UTF8 | ConvertFrom-Json

$fixes = @{
    "auto-healer.ps1" = "auto-healer-v2.ps1"
    "knowledge-organizer.ps1" = "obsidian-knowledge-organizer.ps1"
}

$disabled = @()
$fixed = @()
$stillBroken = @()

foreach ($job in $jobs.jobs) {
    $msg = $job.payload.message
    $wasDisabled = !$job.enabled

    foreach ($wrong in $fixes.Keys) {
        if ($msg -match [regex]::Escape($wrong)) {
            $correct = $fixes[$wrong]
            $msg = $msg -replace [regex]::Escape($wrong), $correct
            $job.payload.message = $msg
            $fixed += "$($job.name): $wrong -> $correct"
        }
    }

    # Check if job still references missing scripts
    $hasMissingScript = $false
    if ($msg -match "auto-healer\.ps1" -and -not (Test-Path "D:\OpenClaw\.openclaw\workspace\scripts\auto-healer.ps1")) {
        # If it's still pointing to auto-healer.ps1 but that doesn't exist
        if ($msg -notmatch "auto-healer-v2\.ps1") {
            $hasMissingScript = $true
        }
    }

    # Re-enable if it was disabled but is now valid
    if ($wasDisabled -and -not $hasMissingScript) {
        $job.enabled = $true
        $disabled += $job.name
    }
}

$jobs | ConvertTo-Json -Depth 10 | Set-Content $jobsPath -Encoding UTF8

Write-Host "=== Fixed Scripts ==="
$fixed | ForEach-Object { Write-Host $_ }

Write-Host ""
Write-Host "=== Re-enabled Jobs ==="
$disabled | ForEach-Object { Write-Host $_ }

Write-Host ""
Write-Host "Done. Total fixed: $($fixed.Count), Re-enabled: $($disabled.Count)"
