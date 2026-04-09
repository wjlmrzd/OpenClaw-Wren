# Session Archive Script v2
# 从 agent main session JSONL 文件归档近期消息到 memory/sessions/

param(
    [int]$Hours = 4,
    [string]$OutDir = "memory\sessions"
)

$ErrorActionPreference = "SilentlyContinue"
$openclawDir = "D:\OpenClaw\.openclaw"

# 找到 main session 的 JSONL 文件
$sessionsJson = Join-Path $openclawDir "agents\main\sessions\sessions.json"
if (-not (Test-Path $sessionsJson)) {
    Write-Host "sessions.json not found"
    exit 0
}

$json = Get-Content $sessionsJson -Raw -Encoding UTF8 | ConvertFrom-Json
$mainSession = $json.PSObject.Properties | Where-Object { $_.Name -eq "agent:main:main" } | Select-Object -First 1
if (-not $mainSession) {
    Write-Host "agent:main:main not found"
    exit 0
}

$sessionFile = $mainSession.Value.sessionFile
if (-not $sessionFile -or -not (Test-Path $sessionFile)) {
    Write-Host "sessionFile not found: $sessionFile"
    exit 0
}

# 读取所有行
$allLines = Get-Content $sessionFile -Encoding UTF8 | Where-Object { $_ -ne "" }
$cutoff = (Get-Date).AddHours(-$Hours)

$newMessages = @()
foreach ($line in $allLines) {
    $entry = ConvertFrom-Json $line
    if ($entry.type -ne "message") { continue }

    # 解析时间戳
    $ts = $null
    if ($entry.timestamp) {
        try { $ts = [DateTime]::Parse($entry.timestamp).ToUniversalTime() } catch { continue }
    }
    if (-not $ts -or $ts -lt $cutoff) { continue }

    # 提取消息内容
    $role = $entry.message.role
    if ($role -eq "system") { continue }  # 跳过 system prompt

    $content = $entry.message.content
    if ($content -is [array]) {
        $textParts = @()
        foreach ($part in $content) {
            if ($part.type -eq "text" -and $part.text) { $textParts += $part.text }
            elseif ($part.type -eq "thinking" -and $part.thinking) { $textParts += "[thinking: $($part.thinking.Substring(0, [Math]::Min(100, $part.thinking.Length)))...]" }
        }
        $text = $textParts -join " "
    } else {
        $text = $content
    }
    if (-not $text) { continue }

    $newMessages += [PSCustomObject]@{
        ts      = $ts.ToString("yyyy-MM-dd HH:mm:ss")
        role    = $role
        content = $text
    }
}

if ($newMessages.Count -eq 0) {
    Write-Host "No new messages in last $Hours hours"
    exit 0
}

# 追加到日期文件
$outDirFull = Join-Path $openclawDir $OutDir
if (-not (Test-Path $outDirFull)) {
    New-Item -ItemType Directory -Force -Path $outDirFull | Out-Null
}

$dateStr = Get-Date -Format "yyyy-MM-dd"
$outFile = Join-Path $outDirFull "$dateStr.jsonl"

# 去重（按 ts）
$existing = @()
if (Test-Path $outFile) {
    $existing = Get-Content $outFile -Encoding UTF8 | Where-Object { $_ -ne "" } | ForEach-Object {
        try { ConvertFrom-Json $_ } catch { $null }
    } | Where-Object { $null -ne $_ }
}
$existingTs = $existing | ForEach-Object { $_.ts } | Sort-Object -Descending | Select-Object -First 1

$count = 0
foreach ($msg in $newMessages | Sort-Object ts) {
    if ($existingTs -and $msg.ts -le $existingTs) { continue }
    $msg | ConvertTo-Json -Compress -Encoding UTF8 | Add-Content -Path $outFile -Encoding UTF8
    $count++
}

Write-Host "Archived $count new messages to $outFile (total in file: $((Get-Content $outFile -Encoding UTF8 | Where-Object { $_ -ne '' }).Count))"
