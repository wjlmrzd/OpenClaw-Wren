$token = $env:TELEGRAM_BOT_TOKEN
$body = @{
    chat_id = "-1003821119875"
    message_thread_id = 39
    name = "主管"
}
$json = $body | ConvertTo-Json -Compress
Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/editForumTopic" -Method Post -ContentType "application/json" -Body $json
