# USER.md Weekly Update Script
# 从本周会话中提炼 Wren 的偏好变化，更新 USER.md

param(
    [int]$Days = 7
)

$openclawDir = "D:\OpenClaw\.openclaw"
$sessionsFile = Join-Path $openclawDir "agents\main\sessions\sessions.json"
$outFile = Join-Path $openclawDir "memory\user_update_pending.md"

$cutoff = (Get-Date).AddDays(-$Days)

# 加载 sessions.json
$json = Get-Content $sessionsFile -Raw -Encoding UTF8 | ConvertFrom-Json

# 找 main session
$mainSession = $json.sessions.PSObject.Properties | Where-Object {
    $_.Value.kind -eq "main"
} | Select-Object -First 1

if (-not $mainSession) { exit 0 }

$messages = @()
foreach ($msg in $mainSession.Value.recentMessages) {
    $ts = $null
    if ($msg.timestamp) { $ts = [DateTimeOffset]::FromUnixTimeMilliseconds($msg.timestamp).DateTime }
    elseif ($msg.ts) { $ts = [DateTimeOffset]::FromUnixTimeMilliseconds($msg.ts).DateTime }
    if ($ts -and $ts -gt $cutoff) {
        $text = if ($msg.content -is [array]) { ($msg.content | ForEach-Object { $_.text }) -join " " } else { $msg.content }
        if ($text -and $msg.role -eq "user") {
            $messages += "[$($ts.ToString('MM-dd HH:mm'))] $text"
        }
    }
}

if ($messages.Count -eq 0) {
    Write-Host "No recent user messages"
    exit 0
}

# 简单摘要：取最近 20 条用户消息供参考
$recent = $messages | Select-Object -Last 20
$header = @"
# USER.md Update Draft - $(Get-Date -Format "yyyy-MM-dd")

## 本周 Wren 的主要互动（最近 20 条）
$($recent -join "`n")

---
**操作建议**：对比当前 USER.md，将本周新增的偏好、习惯、或重要反馈更新进去。
"@

$header | Out-File -FilePath $outFile -Encoding UTF8
Write-Host "Draft written to $outFile"
Write-Host "Summary: $($messages.Count) user messages from last $Days days"
