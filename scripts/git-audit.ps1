Set-Location 'D:\OpenClaw\.openclaw\workspace'
Write-Host "=== Git Status ==="
git status --porcelain
Write-Host "=== Git Diff ==="
git diff --name-only
Write-Host "=== Sensitive Files in git ==="
git ls-files | Select-String -Pattern 'credentials|\.env|token|secret|passwd'
Write-Host "=== Jobs JSON Sample ==="
$jobs = Get-Content 'D:\OpenClaw\.openclaw\cron\jobs.json' -Raw
Write-Host "Length: $($jobs.Length)"
Write-Host "First 500 chars: $($jobs.Substring(0, [Math]::Min(500, $jobs.Length)))"
