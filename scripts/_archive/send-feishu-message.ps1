# send-feishu-message.ps1
# Usage: .\send-feishu-message.ps1 -AppId "xxx" -AppSecret "xxx" -ReceiveId "xxx" -Message "Hello"
# ReceiveIdType: open_id (default), user_id, email, chat_id

param(
    [Parameter(Mandatory=$true)]
    [string]$AppId,
    
    [Parameter(Mandatory=$true)]
    [string]$AppSecret,
    
    [Parameter(Mandatory=$true)]
    [string]$ReceiveId,
    
    [Parameter(Mandatory=$true)]
    [string]$Message,
    
    [string]$ReceiveIdType = "open_id"
)

# Force UTF-8 encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Step 1: Get tenant_access_token
$authBody = '{"app_id":"' + $AppId + '","app_secret":"' + $AppSecret + '"}'
$authBytes = [System.Text.Encoding]::UTF8.GetBytes($authBody)

try {
    $authResp = Invoke-RestMethod `
        -Uri "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" `
        -Method POST `
        -ContentType "application/json; charset=utf-8" `
        -Body $authBytes
} catch {
    Write-Error "Failed to get token: $_"
    exit 1
}

$token = $authResp.tenant_access_token

if (-not $token) {
    Write-Error "tenant_access_token is empty"
    exit 1
}

# Step 2: Build message body
$contentObj = [ordered]@{
    text = $Message
}

$msgObj = [ordered]@{
    receive_id   = $ReceiveId
    msg_type     = "text"
    content      = ($contentObj | ConvertTo-Json -Compress)
}

$msgBody = $msgObj | ConvertTo-Json -Compress
$msgBytes = [System.Text.Encoding]::UTF8.GetBytes($msgBody)

# Step 3: Send message
$headers = @{
    "Authorization" = "Bearer $token"
}

try {
    $resp = Invoke-RestMethod `
        -Uri "https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=$ReceiveIdType" `
        -Method POST `
        -Headers $headers `
        -ContentType "application/json; charset=utf-8" `
        -Body $msgBytes
        
    if ($resp.code -eq 0) {
        Write-Host "Success: $($resp.data.message_id)"
    } else {
        Write-Error "Feishu error: $($resp.msg)"
        exit 1
    }
} catch {
    Write-Error "Request failed: $_"
    exit 1
}
