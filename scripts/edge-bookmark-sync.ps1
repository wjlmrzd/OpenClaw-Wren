# Edge Bookmark Sync Script
param([switch]$Test)

$ErrorActionPreference = "SilentlyContinue"

$BookmarkFile = "$env:USERPROFILE\AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks"
$ObsidianVault = "E:\software\Obsidian\vault"
$NoteFile = "$ObsidianVault\knowledge\收藏夹同步.md"
$StateFile = "$env:USERPROFILE\AppData\Local\openclaw\bookmark-state.json"

# Read bookmarks
$content = Get-Content $BookmarkFile -Raw -Encoding UTF8
$data = $content | ConvertFrom-Json
$roots = $data.roots

# Parse folders recursively
function Get-BookmarkItems {
    param($folder, $path = "")
    $items = @()
    if ($folder.PSObject.Properties.Name -contains "children") {
        foreach ($child in $folder.children) {
            if ($child.type -eq "folder") {
                $newPath = if ($path) { "$path > $($child.name)" } else { $child.name }
                $items += Get-BookmarkItems -folder $child -path $newPath
            } elseif ($child.type -eq "url") {
                $items += [PSCustomObject]@{
                    Path = $path
                    Name = $child.name
                    Url = $child.url
                    Visits = $child.visit_count
                }
            }
        }
    }
    return $items
}

$allBookmarks = @()
$roots.PSObject.Properties | ForEach-Object {
    $allBookmarks += Get-BookmarkItems -folder $_.Value -path $_.Name
}
$total = $allBookmarks.Count

# Check for changes
$currentHash = $content.GetHashCode()
$lastHash = $null
$newItems = @()

if (Test-Path $StateFile) {
    $state = Get-Content $StateFile -Raw | ConvertTo-Json -AsHashtable | ConvertFrom-Json
    if ($state.hash -eq $currentHash) {
        Write-Host "No changes detected"
        exit 0
    }
    if ($state.bookmarks) {
        $oldUrls = @{}
        $state.bookmarks | ForEach-Object { $oldUrls[$_.url] = $true }
        $newItems = $allBookmarks | Where-Object { -not $oldUrls.ContainsKey($_.Url) }
    }
}

# Save state
$newState = @{
    hash = $currentHash
    lastSync = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    count = $total
    bookmarks = $allBookmarks | Select-Object Name, Url, Path, Visits
}
$newState | ConvertTo-Json -Depth 10 | Set-Content $StateFile -Encoding UTF8

# Test mode
if ($Test) {
    Write-Host "=== Bookmark Sync Test ==="
    Write-Host "Total: $total"
    Write-Host "New: $($newItems.Count)"
    return
}

# Generate summary
$lines = @()
$lines += "=== Edge Bookmark Sync ==="
$lines += "Total: $total | New: $($newItems.Count)"
$lines += "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
$lines += ""

if ($newItems) {
    $lines += "[NEW] Recent bookmarks:"
    $newItems | Select-Object -First 15 | ForEach-Object {
        $shortName = if ($_.Name.Length -gt 35) { $_.Name.Substring(0, 32) + "..." } else { $_.Name }
        $lines += "- $shortName ($($_.Path))"
    }
    if ($newItems.Count -gt 15) {
        $lines += "... and $($newItems.Count - 15) more"
    }
}

$message = $lines -join "`n"

# Send to Telegram
try {
    $token = $env:TELEGRAM_BOT_TOKEN
    $chatId = $env:TELEGRAM_CHAT_ID
    if ($token -and $chatId) {
        $body = @{ chat_id = $chatId; text = $message }
        Invoke-RestMethod "https://api.telegram.org/bot$token/sendMessage" -Method Post -Body $body | Out-Null
        Write-Host "[OK] Telegram sent"
    }
} catch { Write-Warning "[ERR] Telegram: $_" }

# Send to Feishu
try {
    $appId = $env:FEISHU_APP_ID
    $appSecret = $env:FEISHU_APP_SECRET
    $userId = $env:FEISHU_DEFAULT_USER
    if ($appId -and $appSecret) {
        $tokenResp = Invoke-RestMethod "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" `
            -Method Post -Body (@{ app_id = $appId; app_secret = $appSecret } | ConvertTo-Json) `
            -ContentType "application/json"
        $headers = @{ Authorization = "Bearer $($tokenResp.tenant_access_token)" }
        $msgBody = @{ receive_id = $userId; msg_type = "text"; content = (@{ text = $message } | ConvertTo-Json) }
        Invoke-RestMethod "https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=open_id" `
            -Method Post -Headers $headers -Body ($msgBody | ConvertTo-Json) -ContentType "application/json" | Out-Null
        Write-Host "[OK] Feishu sent"
    }
} catch { Write-Warning "[ERR] Feishu: $_" }

# Update Obsidian note
try {
    if (Test-Path $ObsidianVault) {
        $noteDir = Split-Path $NoteFile -Parent
        if (-not (Test-Path $noteDir)) { New-Item -ItemType Directory -Path $noteDir -Force | Out-Null }
        
        $note = @"
# Edge Collection Sync

Sync: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Stats
- Total: $total
- New today: $($newItems.Count)

## New Items
$(
    if ($newItems) {
        $newItems | Select-Object -First 20 | ForEach-Object {
            "- [$($_.Name)]($($_.Url)) - $($_.Path)"
        } | Out-String
    } else {
        "None"
    }
)

## Folder Structure
$(
    $allBookmarks | Group-Object { 
        if ($_.Path -match "^(.+?) > [^>]+$") { $Matches[1] } else { "Root" } 
    } | ForEach-Object {
        "- **$($_.Name)**: $($_.Count) items"
    } | Out-String
)

---
Auto-synced by OpenClaw
"@
        $note | Set-Content $NoteFile -Encoding UTF8
        Write-Host "[OK] Obsidian updated"
    }
} catch { Write-Warning "[ERR] Obsidian: $_" }

Write-Host "Done"
