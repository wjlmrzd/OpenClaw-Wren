# Fix garbled characters in cron/jobs.json
$filePath = "D:\OpenClaw\.openclaw\workspace\cron\jobs.json"
$content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)

# Find lines with garbled chars
$lines = $content -split "`n"
$garbledLines = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '\?') {
        $garbledLines += [PSCustomObject]@{
            Line = $i + 1
            Content = $lines[$i].Substring(0, [Math]::Min(150, $lines[$i].Length))
        }
    }
}

Write-Host "Found $($garbledLines.Count) lines with garbled chars:"
$garbledLines | ForEach-Object { Write-Host "Line $($_.Line): $($_.Content)" }

# Fix the known garbled patterns
$fixes = @{
    "浠诲姟鍗忚皟锻炼?" = "任务协调员"
    "日志清理锻炼?" = "日志清理员"
    "配置审计锻炼?" = "配置审计员"
    "资源守护锻炼?" = "资源守护者"
    "灾难恢复锻炼?" = "灾难恢复员"
    "错误恢复锻炼?" = "错误恢复员"
    "检?workspace" = "检查 workspace"
    "执?git commit ?push" = "执行 git commit 和 push"
    "统计本周各模?Token" = "统计本周各模型 Token"
    "检?Gateway" = "检查 Gateway"
    "生成简洁的?每日综合报告?" = "生成简洁的「每日综合报告」"
    "你?OpenClaw" = "你是 OpenClaw"
    "检?今日及明日" = "检查今日及明日"
    "提醒重要会议和截止日期" = "提醒重要会议和截止日期"
    "今日?检?" = "今日检查："
    "项目支持?" = "项目支持："
    "需求分?" = "需求分析"
    "技术规?" = "技术规划"
    "代码生成?" = "代码生成"
    "测试验收?" = "测试验收"
    "进度跟踪?" = "进度跟踪"
    "未完成的功能或待修复?" = "未完成的功能或待修复"
    "待办清单?" = "待办清单"
    "检?git" = "检查 git"
    "本周完成事项?" = "本周完成事项"
    "重要事件?" = "重要事件"
    "下周计划?" = "下周计划"
    "执行 Gateway" = "执行 Gateway"
    "工作日晚间提醒?" = "工作日晚间提醒："
    "检查今日待办?" = "检查今日待办"
    "发送到 Telegram 8542040756" = "发送到 Telegram 8542040756"
    "生成的?每日综合报告?" = "生成简洁的「每日综合报告」"
    "压缩超过 7 天?" = "压缩超过 7 天"
    "删除超过 30 天?" = "删除超过 30 天"
    "清理 cron" = "清理 cron"
    "发送到 Telegram 8542040756" = "发送到 Telegram 8542040756"
    "压缩?删除?" = "压缩/删除"
    "检?openclaw" = "检查 openclaw"
    "生成变更?" = "生成变更"
    "发送到 Telegram 8542040756" = "发送到 Telegram 8542040756"
    "备份文件?" = "备份文件"
    "恢复到?" = "恢复到"
    "恢复到?" = "恢复到"
}

$fixed = $content
$fixCount = 0
foreach ($key in $fixes.Keys) {
    if ($fixed.Contains($key)) {
        $fixed = $fixed.Replace($key, $fixes[$key])
        Write-Host "Fixed: $key -> $($fixes[$key])"
        $fixCount++
    }
}

# Also fix the � followed by ? patterns more broadly
$fixed = $fixed -replace '�\?', '?'
$fixed = $fixed -replace '\?D:', 'D:'
$fixed = $fixed -replace '\?:', ':'
$fixed = $fixed -replace '\?,', ','
$fixed = $fixed -replace '\?5', '5'
$fixed = $fixed -replace '\?1', '1'
$fixed = $fixed -replace '\?T', 'T'
$fixed = $fixed -replace '\?s', "'s"
$fixed = $fixed -replace '\? ]', ']'
$fixed = $fixed -replace '\?\\\\', '\\\\'

# Save fixed content
[System.IO.File]::WriteAllText($filePath, $fixed, [System.Text.Encoding]::UTF8)
Write-Host "`nApplied $fixCount fixes. Saved to $filePath"

# Verify JSON
try {
    $test = $fixed | ConvertFrom-Json
    Write-Host "JSON validation: OK ($($test.jobs.Count) jobs)"
} catch {
    Write-Host "JSON validation: FAILED - $($_.Exception.Message)"
}
