# Resource Guardian - 监控API使用频率和系统资源

# 设置编码为UTF-8
$PSDefaultParameterValues['Out-File:Encoding'] = 'UTF8'

# 读取 codexbar 成本文件
$costFile = "D:\OpenClaw\clawdbot-data\codexbar-costs.json"
$costs = @()
if (Test-Path $costFile) {
    try {
        $jsonData = Get-Content $costFile -Raw -Encoding UTF8
        $costs = $jsonData | ConvertFrom-Json
        if ($costs -eq $null) { $costs = @() }
        if ($costs.GetType().Name -ne 'Object[]') { $costs = @($costs) }
    }
    catch {
        Write-Host "警告: 无法读取成本文件 $costFile : $($_.Exception.Message)"
    }
}

# 计算过去4小时的API使用情况
$fourHoursAgo = (Get-Date).AddHours(-4)
$recentCosts = $costs | Where-Object { 
    $itemTime = [DateTime]$_.timestamp
    $itemTime -ge $fourHoursAgo 
}

# 按模型统计请求次数
$modelStats = @{}
foreach ($item in $recentCosts) {
    $model = if ($item.model) { $item.model } else { "unknown" }
    if ($modelStats.ContainsKey($model)) {
        $modelStats[$model]++
    }
    else {
        $modelStats[$model] = 1
    }
}

# 输出调试信息
Write-Host "Debug: Found $($modelStats.Count) models in usage"

# Coding Plan 模型配额（每小时）
$hourlyLimits = @{}
$limitsList = @(
    'dashscope-coding-plan/qwen3.5-plus',
    'dashscope-coding-plan/qwen3-coder-plus',
    'dashscope-coding-plan/qwen3-coder-next',
    'dashscope-coding-plan/glm-5',
    'dashscope-coding-plan/glm-4.7',
    'dashscope-coding-plan/kimi-k2.5',
    'dashscope-coding-plan/minimax-m2.5'
)

foreach ($model in $limitsList) {
    $hourlyLimits[$model] = 100
}

# 计算配额使用情况
$quotaUsage = @{}
foreach ($model in $modelStats.Keys) {
    $hourlyLimit = if ($hourlyLimits.ContainsKey($model)) { $hourlyLimits[$model] } else { 100 }
    $usage = $modelStats[$model]
    $hourCount = 4  # 过去4小时
    $totalHourlyQuota = $hourlyLimit * $hourCount
    $percentage = [Math]::Round(($usage / $totalHourlyQuota) * 100)
    
    $modelQuota = @{}
    $modelQuota['requests'] = $usage
    $modelQuota['hourlyLimit'] = $hourlyLimit
    $modelQuota['totalQuota'] = $totalHourlyQuota
    $modelQuota['percentage'] = $percentage
    $quotaUsage[$model] = $modelQuota
}

# 获取系统资源信息
try {
    $memoryInfo = Get-Process -Id $PID | Select-Object WorkingSet
    $totalMemory = (Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory
    $memoryPercent = [Math]::Round(($memoryInfo.WorkingSet / $totalMemory) * 100)
}
catch {
    $memoryPercent = 0
}

# 获取磁盘使用情况 (C盘)
try {
    $diskInfo = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskUsage = [Math]::Round(((($diskInfo.Size - $diskInfo.FreeSpace) / $diskInfo.Size) * 100))
}
catch {
    $diskUsage = 0
}

# 构建资源仪表板
$dashboard = "📊 **资源使用仪表板**`n`n"
$dashboard += "**API 使用情况 (过去4小时)**:`n"
if ($quotaUsage.Count -gt 0) {
    foreach ($model in $quotaUsage.Keys) {
        $stats = $quotaUsage[$model]
        $warning = if ($stats['percentage'] -gt 80) { "⚠️" } else { "" }
        $dashboard += "- $model`: $($stats['requests'])/$($stats['totalQuota']) ($($stats['percentage'])%$warning)`n"
    }
} else {
    $dashboard += "- 无API使用记录`n"
}

$dashboard += "`n**系统资源**:`n"
$dashboard += "- 内存使用: $memoryPercent%`n"
$dashboard += "- 磁盘使用: $diskUsage%`n"

# 检查是否需要预警
$hasApiWarning = $false
if ($quotaUsage.Count -gt 0) {
    foreach ($stats in $quotaUsage.Values) {
        if ($stats['percentage'] -gt 80) {
            $hasApiWarning = $true
            break
        }
    }
}

$hasMemoryWarning = $memoryPercent -gt 90
$hasDiskWarning = $diskUsage -gt 85

$severeMemoryWarning = $memoryPercent -gt 95
$severeDiskWarning = $diskUsage -gt 95

# 判断当前是否在静默时段 (22:00-06:00)
$currentHour = (Get-Date).Hour
$isSilentPeriod = $currentHour -ge 22 -or $currentHour -lt 6

# 决定是否发送通知
$shouldSendNotification = $false
$notificationType = "normal"

if ($severeMemoryWarning -or $severeDiskWarning) {
    $shouldSendNotification = $true
    $notificationType = "severe"
}
elseif (!$isSilentPeriod -and ($hasApiWarning -or $hasMemoryWarning -or $hasDiskWarning)) {
    $shouldSendNotification = $true
    $notificationType = "warning"
}

# 输出结果
$result = @{
    'dashboard' = $dashboard
    'hasApiWarning' = $hasApiWarning
    'hasMemoryWarning' = $hasMemoryWarning
    'hasDiskWarning' = $hasDiskWarning
    'severeMemoryWarning' = $severeMemoryWarning
    'severeDiskWarning' = $severeDiskWarning
    'shouldSendNotification' = $shouldSendNotification
    'notificationType' = $notificationType
    'isSilentPeriod' = $isSilentPeriod
    'currentHour' = $currentHour
}

$resultJson = $result | ConvertTo-Json -Depth 5
Write-Output $resultJson

# 如果需要发送通知，则准备消息
if ($shouldSendNotification) {
    $alertMessage = "**⚖️ 资源守护者 - 预警**`n`n"
    
    if ($hasApiWarning) {
        $alertMessage += "⚠️ **API 配额预警**: 以下模型使用率超过80%`n"
        foreach ($model in $quotaUsage.Keys) {
            $stats = $quotaUsage[$model]
            if ($stats['percentage'] -gt 80) {
                $alertMessage += "  - $model`: $($stats['percentage'])%`n"
            }
        }
        $alertMessage += "`n"
    }
    
    if ($hasMemoryWarning) {
        $alertMessage += "⚠️ **内存使用率高**: $memoryPercent% (>90%)`n"
    }
    
    if ($hasDiskWarning) {
        $alertMessage += "⚠️ **磁盘使用率高**: $diskUsage% (>85%)`n"
    }
    
    if ($severeMemoryWarning) {
        $alertMessage += "🚨 **严重内存警告**: $memoryPercent% (>95%) - 建议重启Gateway`n"
    }
    
    if ($severeDiskWarning) {
        $alertMessage += "🚨 **严重磁盘警告**: $diskUsage% (>95%) - 需要清理空间`n"
    }
    
    $alertMessage += "`n$dashboard"
    
    # 确保 temp 目录存在
    $tempDir = "D:\OpenClaw\.openclaw\workspace\temp"
    if (!(Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir -Force
    }
    
    # 写入待发送消息到临时文件
    $alertMessage | Out-File -FilePath "$tempDir\resource-alert.txt" -Encoding UTF8
}