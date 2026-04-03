<#
companion-check.ps1
伴侣系统检查脚本 - 由 cron 每 30 分钟调用

功能：
1. 调用 companion.evaluateCompanion() 检查是否应发送主动消息
2. 如需发送，通过 Gateway 发送到主 session
3. 记录发送状态
#>

$ErrorActionPreference = "Stop"
$repo = "D:\OpenClaw\.openclaw\workspace"

# 读取 OpenClaw Gateway 配置
$gatewayUrl = "http://localhost:18789"
$token = $null

try {
    $envFile = "$repo\.env"
    if (Test-Path $envFile) {
        $lines = Get-Content $envFile
        foreach ($line in $lines) {
            if ($line -match '^GATEWAY_AUTH_TOKEN=(.+)') {
                $token = $matches[1].Trim()
                break
            }
        }
    }
} catch {
    Write-Host "[Companion] Failed to read .env: $_"
    exit 0
}

if (-not $token) {
    Write-Host "[Companion] No gateway token found"
    exit 0
}

# 调用 evaluateCompanion() 的简单版本（直接用 cron 环境变量注入 Python）
# 这里通过 Gateway HTTP API 直接检查是否应该发送

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# 检查当前时间
$now = Get-Date
$hour = $now.Hour
$minute = $now.Minute

# 夜间静音
if ($hour -lt 7 -or $hour -ge 23) {
    Write-Host "[Companion] Night mode (${hour}h), skipping"
    exit 0
}

# 随机采样：只有 15% 的检查轮次真正触发（降低打扰频率）
$random = Get-Random -Minimum 1 -Maximum 100
if ($random -gt 15) {
    Write-Host "[Companion] Random skip (${random}/100)"
    exit 0
}

# 读取伴侣状态
$stateFile = "$repo\memory\companion\state.json"
if (-not (Test-Path $stateFile)) {
    Write-Host "[Companion] No state file, first time setup"
    exit 0
}

$state = Get-Content $stateFile -Raw | ConvertFrom-Json
$lastMsg = $state.lastCompanionMessage
if ($lastMsg -and ((Get-Date).ToUniversalTime().Ticks - $lastMsg) / 3600000 -lt 4) {
    Write-Host "[Companion] Too soon since last message (last: $([Math]::Round(((Get-Date).ToUniversalTime().Ticks - $lastMsg)/3600000, 1))h ago)"
    exit 0
}

# 生成消息（基于时间上下文）
$dayOfWeek = $now.DayOfWeek.Value__
$messages = @{}

# 早安
if ($hour -ge 7 -and $hour -lt 9) {
    $messages['greeting'] = "早安 Wren！新的一天开始了 ☀️"
    if ($dayOfWeek -in @('Tuesday','Thursday','Saturday','Sunday')) {
        $messages['exercise'] = "今天是跑步日，记得去训练 🏃"
    }
}

# 上午工作中
if ($hour -ge 10 -and $hour -lt 12) {
    $messages['checkin'] = "上午工作中，有什么需要我帮忙的吗？"
}

# 午休
if ($hour -eq 12) {
    $messages['lunch'] = "午休时间，记得吃午饭 🍱"
}

# 下午
if ($hour -ge 14 -and $hour -lt 17) {
    $messages['afternoon'] = "下午好，今天进展怎么样？"
}

# 快下班
if ($hour -ge 17 -and $hour -lt 18) {
    $messages['eod'] = "快下班了，今天的主要任务完成了吗？"
}

# 晚间
if ($hour -ge 20 -and $hour -lt 22) {
    $messages['evening'] = "晚上好，还有什么需要处理的吗？"
}

# 选择一条消息（优先 contextual，其次按时间）
$selectedMsg = $null
if ($messages['exercise']) { $selectedMsg = $messages['exercise'] }
elseif ($messages['eod']) { $selectedMsg = $messages['eod'] }
elseif ($messages['afternoon']) { $selectedMsg = $messages['afternoon'] }
elseif ($messages['checkin']) { $selectedMsg = $messages['checkin'] }
elseif ($messages['evening']) { $selectedMsg = $messages['evening'] }
elseif ($messages['lunch']) { $selectedMsg = $messages['lunch'] }
elseif ($messages['greeting']) { $selectedMsg = $messages['greeting'] }

if (-not $selectedMsg) {
    Write-Host "[Companion] No message for hour ${hour}"
    exit 0
}

# 发送消息到主 session (topic 166 = 总脑)
Write-Host "[Companion] Sending: $selectedMsg"

try {
    $body = @{
        channel = "telegram"
        target = "-1003866951105:166"
        message = $selectedMsg
        threadId = "166"
    } | ConvertTo-Json -Compress

    $response = Invoke-RestMethod -Uri "$gatewayUrl/api/chat/send" `
        -Method POST `
        -Headers $headers `
        -Body $body `
        -TimeoutSec 10

    # 更新状态
    $state.lastCompanionMessage = (Get-Date).ToUniversalTime().Ticks
    $state | ConvertTo-Json | Set-Content $stateFile -Encoding UTF8
    Write-Host "[Companion] Message sent successfully"
} catch {
    Write-Host "[Companion] Failed to send: $_"
    exit 1
}
