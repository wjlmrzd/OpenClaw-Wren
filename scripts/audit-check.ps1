$ErrorActionPreference = 'SilentlyContinue'
$results = @{}

$config = Get-Content 'D:\OpenClaw\.openclaw\openclaw.json' | ConvertFrom-Json
$results['configLastTouched'] = $config.lastTouchedAt
$results['configVersion'] = $config.version

$jobsFile = 'D:\OpenClaw\.openclaw\cron\jobs.json'
if (Test-Path $jobsFile) {
    $jobs = Get-Content $jobsFile | ConvertFrom-Json
    $results['cronJobCount'] = $jobs.Count
    $results['cronLastModified'] = (Get-Item $jobsFile).LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
}

$credDir = 'D:\OpenClaw\.openclaw\credentials'
if (Test-Path $credDir) {
    $files = Get-ChildItem $credDir -File
    $results['credentialsCount'] = $files.Count
    $results['credentialsFiles'] = @($files | ForEach-Object { $_.Name })
}

Set-Location 'D:\OpenClaw\.openclaw\workspace'
$gitStatus = git status --porcelain 2>$null
$results['gitClean'] = [string]::IsNullOrWhiteSpace($gitStatus)
if ($gitStatus) {
    $results['gitStatus'] = $gitStatus -split "`n" | Where-Object { $_ -match 'credentials|\.env|token|secret|passwd' }
    $results['sensitiveGitAlert'] = $true
}

$results | ConvertTo-Json -Depth 4
