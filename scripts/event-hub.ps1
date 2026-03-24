# Event Hub - 事件协调中心
# 收集所有 agent 事件，识别系统状态，触发联动

param(
    [switch]$Analyze,
    [switch]$TriggerActions,
    [switch]$Report
)

$workspaceRoot = "D:\OpenClaw\.openclaw\workspace"
$eventsLogPath = Join-Path $workspaceRoot "memory\events.log"
$eventsStatePath = Join-Path $workspaceRoot "memory\events-state.json"
$eventHubStatePath = Join-Path $workspaceRoot "memory\event-hub-state.json"

# 系统阈值配置
$thresholds = @{
    memory_warning = 90
    memory_critical = 95
    disk_warning = 85
    disk_critical = 95
    api_usage_warning = 80
    api_usage_critical = 95
}

Write-Host "=== Event Hub 事件协调中心 ===" -ForegroundColor Cyan
Write-Host "检查时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# ==================== 1. 读取事件日志 ====================
Write-Host "[1/4] 读取事件日志..." -ForegroundColor Yellow

$recentEvents = @()
if (Test-Path $eventsLogPath) {
    try {
        $recentEvents = Get-Content $eventsLogPath -Tail 200 | ConvertFrom-Json
        Write-Host "  读取到 $($recentEvents.Count) 条事件" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ 无法解析事件日志" -ForegroundColor Red
    }
} else {
    Write-Host "  ℹ 事件日志不存在" -ForegroundColor Gray
}

# ==================== 2. 分析事件模式 ====================
Write-Host "[2/4] 分析事件模式..." -ForegroundColor Yellow

$eventAnalysis = @{
    total = $recentEvents.Count
    byLevel = @{}
    byType = @{}
    recentErrors = @()
    trending = @()
}

if ($recentEvents.Count -gt 0) {
    # 按级别统计
    $eventAnalysis.byLevel = ($recentEvents | Group-Object level | ForEach-Object {
        @{ $_.Name = $_.Count }
    }) | Reduce-Hashtable
    
    # 按类型统计
    $eventAnalysis.byType = ($recentEvents | Group-Object type | ForEach-Object {
        @{ $_.Name = $_.Count }
    }) | Reduce-Hashtable
    
    # 最近错误
    $eventAnalysis.recentErrors = $recentEvents | 
        Where-Object { $_.level -eq "error" } | 
        Select-Object -First 10
    
    Write-Host "  事件级别分布:" -ForegroundColor Gray
    foreach ($level in $eventAnalysis.byLevel.GetEnumerator()) {
        $color = switch ($level.Key) {
            "error" { "Red" }
            "warning" { "Yellow" }
            "success" { "Green" }
            default { "Gray" }
        }
        Write-Host "    $($level.Key): $($level.Value)" -ForegroundColor $color
    }
}

# ==================== 3. 检查系统状态 ====================
Write-Host "[3/4] 检查系统状态..." -ForegroundColor Yellow

$systemState = @{
    memory = @{ value = 0; status = "unknown" }
    disk = @{ value = 0; status = "unknown" }
    gateway = @{ status = "unknown" }
    cron = @{ errorCount = 0; status = "unknown" }
}

# 内存状态
try {
    $os = Get-WmiObject Win32_OperatingSystem
    $totalMemory = $os.TotalVisibleMemorySize
    $freeMemory = $os.FreePhysicalMemory
    $memoryPercent = [math]::Round(((($totalMemory - $freeMemory) / $totalMemory) * 100), 1)
    $systemState.memory.value = $memoryPercent
    $systemState.memory.status = if ($memoryPercent -gt $thresholds.memory_critical) { "critical" }
                                  elseif ($memoryPercent -gt $thresholds.memory_warning) { "warning" }
                                  else { "ok" }
    Write-Host "  内存：${memoryPercent}% [$($systemState.memory.status)]" -ForegroundColor $(
        if ($systemState.memory.status -eq "critical") { "Red" }
        elseif ($systemState.memory.status -eq "warning") { "Yellow" }
        else { "Green" }
    )
} catch {
    Write-Host "  内存：无法获取" -ForegroundColor Gray
}

# 磁盘状态
try {
    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskPercent = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1)
    $systemState.disk.value = $diskPercent
    $systemState.disk.status = if ($diskPercent -gt $thresholds.disk_critical) { "critical" }
                                elseif ($diskPercent -gt $thresholds.disk_warning) { "warning" }
                                else { "ok" }
    Write-Host "  磁盘：${diskPercent}% [$($systemState.disk.status)]" -ForegroundColor $(
        if ($systemState.disk.status -eq "critical") { "Red" }
        elseif ($systemState.disk.status -eq "warning") { "Yellow" }
        else { "Green" }
    )
} catch {
    Write-Host "  磁盘：无法获取" -ForegroundColor Gray
}

# Gateway 状态
try {
    $gatewayStatus = & openclaw gateway status 2>&1 | Out-String
    if ($gatewayStatus -match "running|active|ok") {
        $systemState.gateway.status = "ok"
        Write-Host "  Gateway: [ok]" -ForegroundColor Green
    } else {
        $systemState.gateway.status = "warning"
        Write-Host "  Gateway: [warning]" -ForegroundColor Yellow
    }
} catch {
    $systemState.gateway.status = "error"
    Write-Host "  Gateway: [error]" -ForegroundColor Red
}

# Cron 错误计数
try {
    $cronList = & openclaw cron list 2>&1 | Out-String
    $errorCount = ($cronList -split "`n" | Where-Object { $_ -match '\serror\s' }).Count
    $systemState.cron.errorCount = $errorCount
    $systemState.cron.status = if ($errorCount -gt 3) { "critical" }
                               elseif ($errorCount -gt 0) { "warning" }
                               else { "ok" }
    Write-Host "  Cron 错误：${errorCount} [$($systemState.cron.status)]" -ForegroundColor $(
        if ($systemState.cron.status -eq "critical") { "Red" }
        elseif ($systemState.cron.status -eq "warning") { "Yellow" }
        else { "Green" }
    )
} catch {
    Write-Host "  Cron: 无法获取" -ForegroundColor Gray
}

# ==================== 4. 触发联动动作 ====================
Write-Host "[4/4] 触发联动动作..." -ForegroundColor Yellow

$triggeredActions = @()

if ($TriggerActions) {
    # 内存过高 → 触发日志清理
    if ($systemState.memory.status -eq "critical") {
        Write-Host "  ⚡ 内存严重过高，触发日志清理..." -ForegroundColor Red
        $triggeredActions += @{
            action = "trigger_log_cleanup"
            reason = "memory_critical"
            value = $systemState.memory.value
            timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        }
        # 记录事件
        & powershell -File "$workspaceRoot\scripts\event-logger.ps1" `
            -EventType "memory_critical" `
            -Message "内存使用率 ${$systemState.memory.value}%，触发日志清理" `
            -Level "error" `
            -Source "event_hub"
    }
    
    # 磁盘过高 → 强制日志清理
    if ($systemState.disk.status -eq "critical") {
        Write-Host "  ⚡ 磁盘严重过高，强制日志清理..." -ForegroundColor Red
        $triggeredActions += @{
            action = "force_log_cleanup"
            reason = "disk_critical"
            value = $systemState.disk.value
            timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        }
        & powershell -File "$workspaceRoot\scripts\event-logger.ps1" `
            -EventType "disk_critical" `
            -Message "磁盘使用率 ${$systemState.disk.value}%，强制日志清理" `
            -Level "error" `
            -Source "event_hub"
    }
    
    # Gateway 异常 → 通知 auto_healer
    if ($systemState.gateway.status -eq "error") {
        Write-Host "  ⚡ Gateway 异常，通知 auto_healer..." -ForegroundColor Red
        $triggeredActions += @{
            action = "notify_auto_healer"
            reason = "gateway_error"
            timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        }
        & powershell -File "$workspaceRoot\scripts\event-logger.ps1" `
            -EventType "gateway_error" `
            -Message "Gateway 服务异常，已通知 auto_healer" `
            -Level "error" `
            -Source "event_hub"
    }
    
    # Cron 错误过多 → 触发修复
    if ($systemState.cron.status -eq "critical") {
        Write-Host "  ⚡ Cron 错误过多，触发修复流程..." -ForegroundColor Red
        $triggeredActions += @{
            action = "trigger_auto_healer"
            reason = "cron_errors_critical"
            count = $systemState.cron.errorCount
            timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        }
        & powershell -File "$workspaceRoot\scripts\event-logger.ps1" `
            -EventType "cron_errors_critical" `
            -Message "Cron 错误任务 ${$systemState.cron.errorCount} 个，触发自动修复" `
            -Level "error" `
            -Source "event_hub"
    }
    
    if ($triggeredActions.Count -eq 0) {
        Write-Host "  ✓ 无需触发联动动作" -ForegroundColor Green
    } else {
        Write-Host "  已触发 $($triggeredActions.Count) 个联动动作" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ℹ 跳过联动动作 (使用 -TriggerActions 启用)" -ForegroundColor Gray
}

# ==================== 保存状态 ====================
$hubState = [PSCustomObject]@{
    lastCheck = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    systemState = $systemState
    eventAnalysis = $eventAnalysis
    triggeredActions = $triggeredActions
    thresholds = $thresholds
}

$hubState | ConvertTo-Json -Depth 10 | Set-Content -Path $eventHubStatePath

# ==================== 输出报告 ====================
if ($Report) {
    Write-Host ""
    Write-Host "=== Event Hub 状态报告 ===" -ForegroundColor Cyan
    Write-Host "系统状态:" -ForegroundColor Yellow
    Write-Host "  内存：$($systemState.memory.value)% [$($systemState.memory.status)]"
    Write-Host "  磁盘：$($systemState.disk.value)% [$($systemState.disk.status)]"
    Write-Host "  Gateway: [$($systemState.gateway.status)]"
    Write-Host "  Cron 错误：$($systemState.cron.errorCount) [$($systemState.cron.status)]"
    Write-Host ""
    Write-Host "联动动作：$($triggeredActions.Count)" -ForegroundColor Yellow
    foreach ($action in $triggeredActions) {
        Write-Host "  - $($action.action): $($action.reason)"
    }
}

# 返回 JSON 结果
$hubState | ConvertTo-Json -Depth 10
