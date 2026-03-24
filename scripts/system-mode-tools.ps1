# 系统运行模式管理工具

function Get-SystemMode {
    $statePath = "memory/system-mode-state.json"
    if (Test-Path $statePath) {
        $state = Get-Content $statePath -Raw | ConvertFrom-Json
        return $state.currentMode
    }
    return "normal"
}

function Get-SystemResources {
    $resources = @{
        memory = $null
        disk = $null
        gateway = $null
    }
    
    # 内存使用率
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $memPercent = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)
        $resources.memory = $memPercent
    }
    catch {
        $resources.memory = $null
    }
    
    # 磁盘使用率 (D 盘)
    try {
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='D:'"
        if ($disk) {
            $diskPercent = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 2)
            $resources.disk = $diskPercent
        }
    }
    catch {
        $resources.disk = $null
    }
    
    # Gateway 健康状态
    try {
        $response = Invoke-WebRequest -Uri "http://127.0.0.1:18789/status" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        $resources.gateway = @{ status = "healthy"; responseTime = $response.ResponseTime }
    }
    catch {
        $resources.gateway = @{ status = "unhealthy"; error = $_.Exception.Message }
    }
    
    return $resources
}

function Test-ShouldChangeMode {
    param(
        [string]$CurrentMode,
        [object]$Resources
    )
    
    $memory = $Resources.memory
    $disk = $Resources.disk
    $gateway = $Resources.gateway
    
    # 检查是否需要进入安全模式
    if ($memory -ge 95 -or $disk -ge 95 -or $gateway.status -eq "unhealthy") {
        return "safe"
    }
    
    # 检查是否需要进入降载模式
    if ($memory -ge 85 -or $disk -ge 85) {
        return "reduced"
    }
    
    # 当前模式可以保持
    return $CurrentMode
}

function Set-SystemMode {
    param(
        [string]$NewMode,
        [string]$Reason = ""
    )
    
    $statePath = "memory/system-mode-state.json"
    $state = Get-Content $statePath -Raw | ConvertFrom-Json
    
    $oldMode = $state.currentMode
    $timestamp = Get-Date -UFormat %s
    
    # 记录模式变更历史
    if ($oldMode -ne $NewMode) {
        $state.modeHistory += @{
            from = $oldMode
            to = $NewMode
            timestamp = [int64]($timestamp + "000")
            reason = $Reason
        }
        
        $state.lastModeChange = [int64]($timestamp + "000")
        $state.currentMode = $NewMode
        
        # 更新统计
        $state.statistics.totalModeChanges++
    }
    
    # 保存状态
    $state | ConvertTo-Json -Depth 10 | Set-Content $statePath -Encoding UTF8
    
    Write-Host "系统模式已更改：$oldMode → $NewMode (原因：$Reason)"
    
    return @{
        OldMode = $oldMode
        NewMode = $NewMode
        Reason = $Reason
        Timestamp = $timestamp
    }
}

function Get-PausedTasks {
    param([string]$Mode)
    
    $paused = @()
    
    if ($Mode -eq "reduced") {
        # 降载模式：暂停低优先级任务
        $paused = @(
            "0e63f087-5446-4033-b826-19dafe65673b",  # 每日早报
            "b41843c3-9956-4992-860d-df21cd03a766",  # 网站监控员
            "e0a4f1f8-f1e0-e0a4-f1f8-f1e0e0a4f1f8",  # 运动提醒员
            "f1f8f1e0-e0a4-f1f8-f1e0-e0a4f1f8f1e0"   # 每周总结
        )
    }
    elseif ($Mode -eq "safe") {
        # 安全模式：暂停所有非核心任务
        $paused = @(
            "0e63f087-5446-4033-b826-19dafe65673b",  # 每日早报
            "b41843c3-9956-4992-860d-df21cd03a766",  # 网站监控员
            "e0a4f1f8-f1e0-e0a4-f1f8-f1e0e0a4f1f8",  # 运动提醒员
            "f1f8f1e0-e0a4-f1f8-f1e0-e0a4f1f8f1e0",  # 每周总结
            "f920c2a2-6afc-4fc8-84ad-01593d2d22d1",  # 资源守护者
            "5d0f90c4-8e0a-4f1f-8f1e-0e0a4f1f8f1e",  # 配置审计师
            "c2e0a4f1-8f1e-0e0a-4f1f-8f1e0e0a4f1f"   # 安全审计员
        )
    }
    
    return $paused
}

function Update-SystemMode {
    $statePath = "memory/system-mode-state.json"
    $state = Get-Content $statePath -Raw | ConvertFrom-Json
    
    # 获取当前资源状态
    $resources = Get-SystemResources
    
    # 更新触发器状态
    $state.triggers.memory.current = $resources.memory
    $state.triggers.memory.lastCheck = [int64]((Get-Date -UFormat %s) + "000")
    $state.triggers.disk.current = $resources.disk
    $state.triggers.disk.lastCheck = [int64]((Get-Date -UFormat %s) + "000")
    
    # 检查是否需要切换模式
    $newMode = Test-ShouldChangeMode -CurrentMode $state.currentMode -Resources $resources
    
    if ($newMode -ne $state.currentMode) {
        # 模式切换
        $result = Set-SystemMode -NewMode $newMode -Reason "自动检测：内存=$($resources.memory)%, 磁盘=$($resources.disk)%"
        
        # 获取需要暂停的任务
        $pausedTasks = Get-PausedTasks -Mode $newMode
        $state.pausedTasks = $pausedTasks
        
        # 更新活动任务列表
        $state.activeTasks = $state.priorityConfig.high
        
        if ($newMode -eq "normal") {
            $state.activeTasks += $state.priorityConfig.medium + $state.priorityConfig.low
        }
        elseif ($newMode -eq "reduced") {
            $state.activeTasks += $state.priorityConfig.medium
        }
        
        # 保存状态
        $state | ConvertTo-Json -Depth 10 | Set-Content $statePath -Encoding UTF8
        
        # 发送通知
        if ($newMode -eq "safe") {
            Write-Host "🔴 紧急：系统进入安全模式！"
            # 这里可以调用 Send-Telegram
        }
        
        return $result
    }
    
    # 保存资源状态
    $state | ConvertTo-Json -Depth 10 | Set-Content $statePath -Encoding UTF8
    
    return $null
}

# 导出函数
Export-ModuleMember -Function Get-SystemMode, Get-SystemResources, Test-ShouldChangeMode, Set-SystemMode, Get-PausedTasks, Update-SystemMode
