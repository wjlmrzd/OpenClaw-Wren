# Direct string replacement
$file = "D:\OpenClaw\.openclaw\workspace\memory\cron-list.json"

# Read as UTF-16LE, skip BOM (first 2 bytes)
$bytes = [System.IO.File]::ReadAllBytes($file)
if ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
    $text = [System.Text.Encoding]::Unicode.GetString($bytes, 2, $bytes.Length - 2)
} else {
    $text = [System.Text.Encoding]::Unicode.GetString($bytes)
}

Write-Host "File read: $($text.Length) chars"
Write-Host ""

$changed = 0

# Fix 1: 健康监控员 "92af6946" - timeout 120 -> 300
$match1 = $text -match '(id.*?92af6946[^}]*?timeoutSeconds":\s*)120(\s*\n\s*"model": "dashscope-coding-plan/qwen3-coder-plus")'
if ($match1) {
    $text = $text -replace '(id.*?92af6946[^}]*?timeoutSeconds":\s*)120(\s*\n\s*"model": "dashscope-coding-plan/qwen3-coder-plus")', '$1300$2'
    $changed++
    Write-Host "Fixed 健康监控员: 120s -> 300s"
}

# Fix 2: 事件协调员 "3a1df011" - timeout 180 -> 300
$match2 = $text -match '(id.*?3a1df011[^}]*?timeoutSeconds":\s*)180(\s*\n\s*"model": "dashscope-coding-plan/qwen3\.5-plus")'
if ($match2) {
    $text = $text -replace '(id.*?3a1df011[^}]*?timeoutSeconds":\s*)180(\s*\n\s*"model": "dashscope-coding-plan/qwen3\.5-plus")', '$1300$2'
    $changed++
    Write-Host "Fixed 事件协调员: 180s -> 300s"
}

# Fix 3: 运动提醒员 "58540a34" - timeout 120 -> 180
$match3 = $text -match '(id.*?58540a34[^}]*?timeoutSeconds":\s*)120(\s*\n\s*"delivery":)'
if ($match3) {
    $text = $text -replace '(id.*?58540a34[^}]*?timeoutSeconds":\s*)120(\s*\n\s*"delivery":)', '$1180$2'
    $changed++
    Write-Host "Fixed 运动提醒员: 120s -> 180s"
}

# Fix 4: 每日早报 "0e63f087" - timeout 450 -> 600
$match4 = $text -match '(id.*?0e63f087[^}]*?timeoutSeconds":\s*)450(\s*\n\s*"delivery":)'
if ($match4) {
    $text = $text -replace '(id.*?0e63f087[^}]*?timeoutSeconds":\s*)450(\s*\n\s*"delivery":)', '$1600$2'
    $changed++
    Write-Host "Fixed 每日早报: 450s -> 600s"
}

# Fix 5: 调度优化员 "b6bc413c" - timeout 600
$match5 = $text -match '(id.*?b6bc413c[^}]*?timeoutSeconds":\s*)(\d+)'
if ($match5) {
    $old = $matches[2]
    if ([int]$old -lt 600) {
        $text = $text -replace '(id.*?b6bc413c[^}]*?timeoutSeconds":\s*)\d+', "$1`$2600"
        $changed++
        Write-Host "Fixed 调度优化员: ${old}s -> 600s"
    } else {
        Write-Host "调度优化员 timeout already: ${old}s"
    }
}

# Fix 6: Add delivery to scheduler if missing
if ($text -notmatch 'b6bc413c[^}]*?"delivery":\s*\{[^}]*announce') {
    $text = $text -replace '(b6bc413c[^}]*?timeoutSeconds":\s*600\s*\n\s*"model": "dashscope-coding-plan/qwen3-coder-plus"\s*\n\s*\})', '$1,"delivery": {"mode": "announce", "channel": "last"}'
    if ($text -match 'b6bc413c[^}]*?announce') {
        $changed++
        Write-Host "Fixed 调度优化员: added delivery config"
    }
}

Write-Host ""
Write-Host "Total changes: $changed"

# Write back as UTF-8 with BOM
$utf8 = [System.Text.Encoding]::UTF8
$writer = New-Object System.IO.StreamWriter($file, $false, $utf8)
$writer.Write($text)
$writer.Close()
Write-Host "Saved (UTF-8)"
