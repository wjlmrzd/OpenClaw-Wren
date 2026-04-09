# Session Archive Script v3 - debug
param(
    [int]$Hours = 48,
    [string]$OutDir = "memory\sessions"
)

$ErrorActionPreference = 'Continue'
$openclawDir = 'D:\OpenClaw\.openclaw'

# Check sessions.json
$sessionsJson = Join-Path $openclawDir "agents\main\sessions\sessions.json"
Write-Host "DEBUG sessionsJson=$sessionsJson exists=$(Test-Path $sessionsJson)"
if (-not (Test-Path $sessionsJson)) { exit 0 }

$json = Get-Content $sessionsJson -Raw -Encoding UTF8 | ConvertFrom-Json
$mainSession = $json.PSObject.Properties | Where-Object { $_.Name -eq "agent:main:main" } | Select-Object -First 1
if (-not $mainSession) { Write-Host "no main session"; exit 0 }

$sessionFile = $mainSession.Value.sessionFile
Write-Host "DEBUG sessionFile=$sessionFile exists=$(Test-Path $sessionFile)"
if (-not $sessionFile -or -not (Test-Path $sessionFile)) { exit 0 }

$allLines = Get-Content $sessionFile -Encoding UTF8 | Where-Object { $_ -ne "" }
Write-Host "DEBUG totalLines=$($allLines.Count)"

$cutoff = (Get-Date).AddHours(-$Hours)

$newMessages = @()
foreach ($line in $allLines) {
    $entry = ConvertFrom-Json $line
    if ($entry.type -ne "message") { continue }
    $ts = $null
    if ($entry.timestamp) {
        try { $ts = [DateTime]::Parse($entry.timestamp).ToUniversalTime() } catch { continue }
    }
    if (-not $ts -or $ts -lt $cutoff) { continue }
    $role = $entry.message.role
    if ($role -eq "system") { continue }
    $content = $entry.message.content
    if ($content -is [array]) {
        $textParts = @()
        foreach ($part in $content) {
            if ($part.type -eq "text" -and $part.text) { $textParts += $part.text }
            elseif ($part.type -eq "thinking" -and $part.thinking) {
                $txt = $part.thinking.Substring(0, [Math]::Min(80, $part.thinking.Length))
                $textParts += "[thinking: $txt...]"
            }
        }
        $text = $textParts -join " "
    } else {
        $text = $content
    }
    if (-not $text) { continue }
    $newMessages += [PSCustomObject]@{ ts = $ts.ToString("yyyy-MM-dd HH:mm:ss"); role = $role; content = $text }
}

Write-Host "DEBUG newMessages.Count=$($newMessages.Count)"
if ($newMessages.Count -eq 0) { Write-Host "No new messages"; exit 0 }

$outDirFull = Join-Path $openclawDir $OutDir
if (-not (Test-Path $outDirFull)) {
    New-Item -ItemType Directory -Force -Path $outDirFull | Out-Null
}

$dateStr = Get-Date -Format 'yyyy-MM-dd'
$outFile = Join-Path $outDirFull "$dateStr.jsonl"
Write-Host "DEBUG outDirFull=$outDirFull"
Write-Host "DEBUG dateStr=[$dateStr]"
Write-Host "DEBUG outFile=$outFile"

# Write test
"[ARCHIVE-START]" | Out-File -FilePath $outFile -Encoding UTF8
Write-Host "WROTE TEST. exists=$(Test-Path $outFile)"
