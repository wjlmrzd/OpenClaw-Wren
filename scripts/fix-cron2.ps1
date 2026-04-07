# Direct string replacement - avoid JSON parsing
$file = "D:\OpenClaw\.openclaw\workspace\memory\cron-list.json"

# Read as UTF-16LE (file has BOM FFFE)
$bytes = [System.IO.File]::ReadAllBytes($file)
$text = [System.Text.Encoding]::Unicode.GetString($bytes)

Write-Host "File read: $($text.Length) chars"
Write-Host ""

$changed = 0

# Fix 1: 健康监控员 - "92af6946" and "timeoutSeconds": 120 + qwen3-coder-plus
if ($text -match '92af6946.*?timeoutSeconds":\s*120(\s*\n\s*"model": "dashscope-coding-plan/qwen3-coder-plus")') {
    $text = $text -replace '(92af6946.*?timeoutSeconds":\s*)120(\s*\n\s*"model": "dashscope-coding-plan/qwen3-coder-plus")', '$1300$2'
    $changed++
    Write-Host "Fixed 健康监控员: 120s -> 300s"
}

# Fix 2: 事件协调员 - "3a1df011" + "timeoutSeconds": 180 + qwen3.5-plus
if ($text -match '3a1df011.*?timeoutSeconds":\s*180(\s*\n\s*"model": "dashscope-coding-plan/qwen3\.5-plus")') {
    $text = $text -replace '(3a1df011.*?timeoutSeconds":\s*)180(\s*\n\s*"model": "dashscope-coding-plan/qwen3\.5-plus")', '$1300$2'
    $changed++
    Write-Host "Fixed 事件协调员: 180s -> 300s"
}

# Fix 3: 运动提醒员 - "58540a34" + timeout 120
if ($text -match '58540a34.*?timeoutSeconds":\s*120(\s*\n\s*"delivery":\s*\{)') {
    $text = $text -replace '(58540a34.*?timeoutSeconds":\s*)120(\s*\n\s*"delivery":\s*\{)', '$1180$2'
    $changed++
    Write-Host "Fixed 运动提醒员: 120s -> 180s"
}

# Fix 4: 每日早报 - "0e63f087" + timeout 450
if ($text -match '0e63f087.*?timeoutSeconds":\s*450(\s*\n\s*"delivery":\s*\{)') {
    $text = $text -replace '(0e63f087.*?timeoutSeconds":\s*)450(\s*\n\s*"delivery":\s*\{)', '$1600$2'
    $changed++
    Write-Host "Fixed 每日早报: 450s -> 600s"
}

# Fix 5: 调度优化员 - "b6bc413c" add delivery config
if ($text -match '(b6bc413c.*?"delivery":\s*\{[^}]*)(\}*\s*\n\s*"state")') {
    Write-Host "Scheduler already has delivery - checking..."
}

# Check scheduler
if ($text -match 'b6bc413c.*?timeoutSeconds":\s*(\d+)') {
    $currentTimeout = [int]$matches[1]
    Write-Host "调度优化员 current timeout: ${currentTimeout}s"
    if ($currentTimeout -lt 600) {
        $text = $text -replace '(b6bc413c.*?timeoutSeconds":\s*)\d+(\s*\n\s*"delivery")', "$1`$2600$2"
        $changed++
        Write-Host "Fixed 调度优化员: ${currentTimeout}s -> 600s"
    }
}

# Add delivery config to scheduler if missing
if ($text -notmatch 'b6bc413c.*?"delivery":\s*\{[^}]*mode[^}]*announce') {
    # Add delivery after scheduler's payload close
    $text = $text -replace '(b6bc413c.*?timeoutSeconds":\s*600\s*\n\s*"model":\s*"dashscope-coding-plan/qwen3-coder-plus"\s*\n\s*\})', '$1,"delivery": {"mode": "announce", "channel": "last"}'
    $changed++
    Write-Host "Fixed 调度优化员: added delivery config"
}

Write-Host ""
Write-Host "Total changes: $changed"

# Write back as UTF-8 with BOM
$bom = [byte[]](0xEF, 0xBB, 0xBF)
$utf8 = [System.Text.Encoding]::UTF8.GetBytes($text)
$all = $bom + $utf8
[System.IO.File]::WriteAllBytes($file, $all)
Write-Host "Saved (UTF-8 with BOM)"
