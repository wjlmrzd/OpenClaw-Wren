# Feishu Bot Webhook - Off-work reminder
# UTF-8 with BOM

# Webhook URL (需要在飞书开放平台配置)
$webhookUrl = "https://open.feishu.cn/open-apis/bot/v2/hook/YOUR_WEBHOOK_KEY"

# Message content
$content = @{
    text = "🕐 下班时间到！`n`n辛苦一天了，早点回家休息吧~ 🏠"
} | ConvertTo-Json -Compress

$body = @{
    msg_type = "text"
    content = $content
} | ConvertTo-Json -Compress

$response = Invoke-RestMethod -Uri $webhookUrl -Method Post -ContentType "application/json" -Body $body

if ($response.StatusCode -eq 0) {
    Write-Host "Success!"
} else {
    Write-Error "Failed: $($response.msg)"
    exit 1
}
