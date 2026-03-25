# Feishu off-work reminder - Unicode escape version
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

# Chinese text using Unicode escape sequences
# 下班时间到！\n\n辛苦一天了，早点回家休息吧~
$chineseEscaped = "\u4E0B\u73ED\u65F6\u95F4\u5230\uFF01\u000A\u000A\u8F9B\u82E6\u4E00\u5929\u4E86\uFF0C\u65E9\u70B9\u56DE\u5BB6\u4F11\u606F\u5427\uFF5E"

# Build JSON - content must be a JSON string (double-encoded)
$contentText = "🕐 $chineseEscaped 🏠"
$contentJson = "{`"text`":`"$contentText`"}"
# Escape the content JSON to make it a string
$contentJsonEscaped = $contentJson -replace '"', '\"'
$requestBody = "{`"receive_id`":`"$userId`",`"msg_type`":`"text`",`"content`":`"$contentJsonEscaped`"}"

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

Write-Host "Request body:"
Write-Host $requestBody
Write-Host ""

$response = Invoke-RestMethod -Uri "https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=open_id" -Method Post -Headers $headers -Body $requestBody

if ($response.code -eq 0) {
    Write-Host "Success! Message ID: $($response.data.message_id)"
} else {
    Write-Error "Failed: $($response.msg)"
    exit 1
}
