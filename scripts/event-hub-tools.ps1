# Event Hub 系统状态检查工具

function Get-SystemStatus {
    $status = @{}
    
    # 内存使用率
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $memPercent = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)
        $status.memory = @{ value = $memPercent; usedMB = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1024, 2) }
    } catch {
        $status.memory = @{ value = $null; error = $_.Exception.Message }
    }
    
    # 磁盘使用率 (D 盘)
    try {
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='D:'"
        if ($disk) {
            $diskPercent = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 2)
            $status.disk = @{ value = $diskPercent; freeGB = [math]::Round($disk.FreeSpace / 1GB, 2) }
        }
    } catch {
        $status.disk = @{ value = $null; error = $_.Exception.Message }
    }
    
    # Gateway 健康状态
    try {
        $response = Invoke-WebRequest -Uri "http://127.0.0.1:18789/status" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        $status.gateway = @{ status = "healthy"; responseTime = [math]::Round($response.ResponseTime, 2) }
    } catch {
        $status.gateway = @{ status = "down"; error = $_.Exception.Message }
    }
    
    return $status
}

function Update-EventHubState {
    param([string]$StatePath = "D:\OpenClaw\.openclaw\workspace\memory\event-hub-state.json")
    
    $currentStatus = Get-SystemStatus
    $existingState = if (Test-Path $StatePath) { Get-Content $StatePath -Raw | ConvertFrom-Json } else { @{ systemHealth = @{}; activeEvents = @() } }
    
    $existingState.lastCheck = [int64]((Get-Date -UFormat %s) + "000")
    if ($currentStatus.memory.value) { $existingState.systemHealth.memory.value = $currentStatus.memory.value }
    if ($currentStatus.disk.value) { $existingState.systemHealth.disk.value = $currentStatus.disk.value }
    $existingState.systemHealth.gateway.status = $currentStatus.gateway.status
    
    # 检测事件
    $events = @()
    if ($currentStatus.memory.value -ge 95) { $events += @{ type = "MEM_CRITICAL"; value = $currentStatus.memory.value } }
    elseif ($currentStatus.memory.value -ge 85) { $events += @{ type = "MEM_HIGH"; value = $currentStatus.memory.value } }
    if ($currentStatus.disk.value -ge 95) { $events += @{ type = "DISK_CRITICAL"; value = $currentStatus.disk.value } }
    elseif ($currentStatus.disk.value -ge 85) { $events += @{ type = "DISK_HIGH"; value = $currentStatus.disk.value } }
    if ($currentStatus.gateway.status -eq "down") { $events += @{ type = "GW_DOWN" } }
    
    $existingState.activeEvents = $events
    $existingState | ConvertTo-Json -Depth 10 | Set-Content $StatePath -Encoding UTF8
    
    return @{ status = $existingState; events = $events }
}
