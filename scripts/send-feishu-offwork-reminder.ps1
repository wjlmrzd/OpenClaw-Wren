# Feishu off-work reminder script
$appId = "cli_a92bb7f3923a5ccb"
$appSecret = "0i4rX06EKNpiU3FmFH0hNYPJbQ2bpYzN"
$userId = "ou_a5c4938f3a1fb4354f765ff9c3fcc68c"
$userIdType = "open_id"

$tokenBody = @{app_id=$appId; app_secret=$appSecret} | ConvertTo-Json
$tokenResp = Invoke-RestMethod -Uri "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" -Method Post -ContentType "application/json" -Body $tokenBody
if ($tokenResp.code -ne 0) { Write-Error "Token failed"; exit 1 }
$token = $tokenResp.tenant_access_token

$headers = @{Authorization="Bearer $token"; "Content-Type"="application/json"}
$messageText = "🕐 下班时间到！辛苦一天了，早点回家休息吧~ 🏠"
$content = @{text=$messageText} | ConvertTo-Json -Compress
$msg = @{receive_id=$userId; msg_type="text"; content=$content} | ConvertTo-Json -Compress

$response = Invoke-RestMethod -Uri "https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=$userIdType" -Method Post -Headers $headers -Body $msg
if ($response.code -eq 0) { Write-Host "Success: $($response.data.message_id)" } else { Write-Error "Failed: $($response.msg)"; exit 1 }