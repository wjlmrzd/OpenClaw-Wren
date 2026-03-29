# Feishu Test Script
$appId = "cli_a92bb7f3923a5ccb"
$appSecret = "0i4rX06EKNpiU3FmFH0hNYPJbQ2bpYzN"
$userId = "ou_a5c4938f3a1fb4354f765ff9c3fcc68c"

# Get token
$tokenBody = @{app_id=$appId; app_secret=$appSecret} | ConvertTo-Json
$tokenResp = Invoke-RestMethod -Uri "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" -Method Post -ContentType "application/json; charset=utf-8" -Body $tokenBody
$token = $tokenResp.tenant_access_token
Write-Host "Token obtained: $token"

# Test 1: English message
Write-Host "`n=== Test 1: English ==="
$content1 = '{"text":"Off work time! Have a great evening! 馃彔"}'
$msg1 = @{receive_id=$userId; msg_type="text"; content=$content1} | ConvertTo-Json -Compress
$headers = @{Authorization="Bearer $token"; "Content-Type"="application/json; charset=utf-8"}
$response1 = Invoke-RestMethod -Uri "https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=open_id" -Method Post -Headers $headers -Body $msg1
if ($response1.code -eq 0) { Write-Host "鉁?English Success: $($response1.data.message_id)" } else { Write-Host "鉂?Error: $($response1.msg)" }

# Test 2: Chinese message
Write-Host "`n=== Test 2: Chinese ==="
$content2 = '{"text":"涓嬬彮鏃堕棿鍒帮紒杈涜嫤涓€澶╀簡锛屾棭鐐瑰洖瀹朵紤鎭惂~"}'
$msg2 = @{receive_id=$userId; msg_type="text"; content=$content2} | ConvertTo-Json -Compress
$response2 = Invoke-RestMethod -Uri "https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=open_id" -Method Post -Headers $headers -Body $msg2
if ($response2.code -eq 0) { Write-Host "鉁?Chinese Success: $($response2.data.message_id)" } else { Write-Host "鉂?Error: $($response2.msg)" }

# Test 3: Simple emoji
Write-Host "`n=== Test 3: Emoji Only ==="
$content3 = '{"text":"馃晲馃彔"}'
$msg3 = @{receive_id=$userId; msg_type="text"; content=$content3} | ConvertTo-Json -Compress
$response3 = Invoke-RestMethod -Uri "https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=open_id" -Method Post -Headers $headers -Body $msg3
if ($response3.code -eq 0) { Write-Host "鉁?Emoji Success: $($response3.data.message_id)" } else { Write-Host "鉂?Error: $($response3.msg)" }

Write-Host "`n=== All tests completed ==="
