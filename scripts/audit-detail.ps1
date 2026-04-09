$ErrorActionPreference = 'SilentlyContinue'
$results = @{}

# Config details
$config = Get-Content 'D:\OpenClaw\.openclaw\openclaw.json' | ConvertFrom-Json
$results['openclawVersion'] = $config.openclaw
$results['configHasLastTouched'] = $null -ne $config.lastTouchedAt
$results['configLastTouched'] = $config.lastTouchedAt

# Cron details - correct path for count
$jobsContent = Get-Content 'D:\OpenClaw\.openclaw\cron\jobs.json' -Raw | ConvertFrom-Json
$results['cronJobCount'] = $jobsContent.jobs.Count
$results['cronEnabledCount'] = @($jobsContent.jobs | Where-Object { $_.enabled -eq $true }).Count

# Credentials
$credDir = 'D:\OpenClaw\.openclaw\credentials'
if (Test-Path $credDir) {
    $results['credentialsFiles'] = @((Get-ChildItem $credDir -File).Name)
    $results['credentialsCount'] = (Get-ChildItem $credDir -File).Count
}

# Git
Set-Location 'D:\OpenClaw\.openclaw\workspace'
$status = git status --porcelain 2>$null
$modified = ($status | Where-Object { $_ -match '^ M' }).Count
$untracked = ($status | Where-Object { $_ -match '^\?\?' }).Count
$results['gitModified'] = $modified
$results['gitUntracked'] = $untracked
$results['gitClean'] = ($modified -eq 0 -and $untracked -eq 0)

# Sensitive check
$tracked = git ls-files 2>$null | Select-String -Pattern 'credentials/|\.env$|token.*=|secret.*=|passwd' -SimpleMatch
$results['sensitiveTracked'] = $null -ne $tracked

# Credentials permissions check
$aclIssues = @()
foreach ($f in Get-ChildItem $credDir -File) {
    $acl = Get-Acl $f.FullName
    if ($acl.Owner -notmatch 'Administrator|SYSTEM') {
        $aclIssues += "$($f.Name): Owner=$($acl.Owner)"
    }
}
$results['aclIssues'] = $aclIssues

$results | ConvertTo-Json -Depth 4
