$body = @{
    chat_id = "-1003866951105"
    name = "总脑"
} | ConvertTo-Json -Compress

$proxy = "http://127.0.0.1:7897"
$webSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$webSession.Proxy = New-Object System.Net.WebProxy($proxy)

$response = Invoke-RestMethod -Uri "https://api.telegram.org/bot8329757047:AAEas5LRhvSSGBY6t0zsHzyV8nv_8CZyczA/createForumTopic" -Method Post -ContentType "application/json" -Body $body -WebSession $webSession
$response | ConvertTo-Json -Depth 10
