# Feishu User Query Script
# UTF-8 with BOM

$appId = "cli_a92bb7f3923a5ccb"
$appSecret = "0i4rX06EKNpiU3FmFH0hNYPJbQ2bpYzN"

# Get tenant access token
$tokenBody = @{app_id=$appId; app_secret=$appSecret} | ConvertTo-Json
$tokenResp = Invoke-RestMethod -Uri "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" -Method Post -ContentType "application/json" -Body $tokenBody

if ($tokenResp.code -ne 0) {
    Write-Host "Error: $($tokenResp.msg)"
    exit 1
}

$token = $tokenResp.tenant_access_token
Write-Host "Token obtained successfully"

# Get user list
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer $token")

$userResp = Invoke-RestMethod -Uri "https://open.feishu.cn/open-apis/contact/v3/users?user_id_type=open_id&pageSize=50" -Method Get -Headers $headers

if ($userResp.code -ne 0) {
    Write-Host "Error: $($userResp.msg)"
    exit 1
}

Write-Host ""
Write-Host "=== 可访问的用户列表 ===" -ForegroundColor Green
Write-Host ""

foreach ($user in $userResp.data.items) {
    $name = if ($user.name) { $user.name } else { "N/A" }
    $openId = if ($user.open_id) { $user.open_id } else { "N/A" }
    $unionId = if ($user.union_id) { $user.union_id } else { "N/A" }
    $mobile = if ($user.mobile) { $user.mobile } else { "N/A" }
    $email = if ($user.email) { $user.email } else { "N/A" }
    
    Write-Host "姓名：$name" -ForegroundColor Cyan
    Write-Host "  用户 ID (open_id): $openId" -ForegroundColor Yellow
    Write-Host "  用户 ID (union_id): $unionId"
    Write-Host "  手机号：$mobile"
    Write-Host "  邮箱：$email"
    Write-Host "---"
}
