$token = [System.Environment]::GetEnvironmentVariable('TELEGRAM_BOT_TOKEN', 'Process')
$body = @{
    chat_id = -1003866951105
    name = "动人心弦"
} | ConvertTo-Json

$params = @{
    Uri = "https://api.telegram.org/bot$token/createForumTopic"
    Method = "Post"
    ContentType = "application/json"
    Body = $body
}

try {
    $result = Invoke-RestMethod @params
    $result | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Error: $_"
    $_.Exception.Response
}
