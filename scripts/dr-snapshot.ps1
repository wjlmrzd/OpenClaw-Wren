$ts = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$dr = 'D:\OpenClaw\.openclaw\workspace\memory\disaster-recovery'
$openclawPath = 'D:\OpenClaw\.openclaw\openclaw.json'
$cronPath = 'D:\OpenClaw\.openclaw\cron\jobs.json'

# 1. Snapshot openclaw.json
Copy-Item $openclawPath "$dr\openclaw-$ts.json" -Force
Write-Host "[OK] openclaw snapshot"

# 2. Export cron jobs
if (Test-Path $cronPath) {
    Copy-Item $cronPath "$dr\cron-jobs-$ts.json" -Force
    Write-Host "[OK] cron snapshot"
}

# 3. Credentials summary (no actual secrets)
$credPath = 'D:\OpenClaw\.openclaw\.env'
$credSummary = @{}
if (Test-Path $credPath) {
    Get-Content $credPath | ForEach-Object {
        if ($_ -match '^([^=]+)=') {
            $credSummary[$matches[1]] = '[REDACTED - see .env]'
        }
    }
}
$credSummary | ConvertTo-Json -Depth 3 | Out-File "$dr\credentials-$ts.json" -Encoding UTF8
Write-Host "[OK] credentials snapshot"

# 4. Skills manifest
$skillsDir = 'D:\OpenClaw\.openclaw\workspace\skills'
$skillsList = @()
if (Test-Path $skillsDir) {
    Get-ChildItem $skillsDir -Directory | ForEach-Object {
        $skillPath = $_.FullName
        $desc = ''
        $skFile = "$skillPath\SKILL.md"
        if (Test-Path $skFile) {
            $content = Get-Content $skFile -Raw
            if ($content -match '(?i)description[:\s]+([^\n]+)') {
                $desc = $matches[1].Trim()
            }
        }
        $skillsList += [PSCustomObject]@{
            Name = $_.Name
            Description = $desc
            Path = $skillPath
        }
    }
}
$skillsList | ConvertTo-Json -Depth 3 | Out-File "$dr\skills-manifest-$ts.json" -Encoding UTF8
Write-Host "[OK] skills manifest snapshot"

# 5. Plugins manifest
$pluginsDir = 'D:\OpenClaw\.openclaw\workspace\plugins'
$pluginsList = @()
if (Test-Path $pluginsDir) {
    Get-ChildItem $pluginsDir -Directory | ForEach-Object {
        $pkgFile = "$($_.FullName)\package.json"
        $version = ''
        $name = $_.Name
        if (Test-Path $pkgFile) {
            $pkg = Get-Content $pkgFile -Raw | ConvertFrom-Json
            $name = $pkg.name
            $version = $pkg.version
        }
        $pluginsList += [PSCustomObject]@{
            Name = $name
            Version = $version
            Path = $_.FullName
        }
    }
}
$pluginsList | ConvertTo-Json -Depth 3 | Out-File "$dr\plugins-manifest-$ts.json" -Encoding UTF8
Write-Host "[OK] plugins manifest snapshot"

# 6. File listing
Write-Host "`n=== Backup Files ==="
Get-ChildItem $dr -File | Sort-Object LastWriteTime -Descending | Select-Object Name, @{N='Size(Bytes)';E={$_.Length}}, LastWriteTime | Format-Table -AutoSize | Out-String

# 7. Verify snapshots are readable JSON
Write-Host "`n=== Integrity Check ==="
$ok = 0; $fail = 0
@("$dr\openclaw-$ts.json", "$dr\cron-jobs-$ts.json", "$dr\credentials-$ts.json") | ForEach-Object {
    if (Test-Path $_) {
        try {
            Get-Content $_ -Raw | ConvertFrom-Json | Out-Null
            Write-Host "[PASS] $_"
            $ok++
        } catch {
            Write-Host "[FAIL] $_ : $_"
            $fail++
        }
    }
}
Write-Host "Integrity: $ok passed, $fail failed"
