# Feishu off-work reminder
# UTF-8 with BOM

$appId = "cli_a92bb7f3923a5ccb"
$appSecret = "0i4rX06EKNpiU3FmFH0hNYPJbQ2bpYzN"
$userId = "ou_a5c4938f3a1fb4354f765ff9c3fcc68c"

# Get token
$tokenBody = @{app_id=$appId; app_secret=$appSecret} | ConvertTo-Json
$tokenResp = Invoke-RestMethod -Uri "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" -Method Post -ContentType "application/json" -Body $tokenBody

if ($tokenResp.code -ne 0) {
    Write-Error "Token failed: $($tokenResp.msg)"
    exit 1
}

$token = $tokenResp.tenant_access_token

# Create JSON content with Chinese text
$contentText = "🕐 下班时间到！`n`n辛苦一天了，早点回家休息吧~ 🏠"
$contentObj = @{text=$contentText}
$contentJson = $contentObj | ConvertTo-Json -Compress

# Build request body
$requestBody = @{
    receive_id = $userId
    msg_type = "text"
    content = $contentJson
} | ConvertTo-Json -Compress

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json; charset=utf-8"
}

# Debug: show request body
Write-Host "Request body:"
Write-Host $requestBody
Write-Host ""

# Send request
$response = Invoke-RestMethod -Uri "https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=open_id" -Method Post -Headers $headers -Body $requestBody

if ($response.code -eq 0) {
    Write-Host "Success! Message ID: $($response.data.message_id)"
} else {
    Write-Error "Failed: $($response.msg)"
    Write-Host "Full response: $($response | ConvertTo-Json -Depth 10)"
    exit 1
}
