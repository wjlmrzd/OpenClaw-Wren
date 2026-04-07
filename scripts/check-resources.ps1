# 资源守护检查脚本
$ErrorActionPreference = 'SilentlyContinue'

# 磁盘使用率
$disk = Get-PSDrive D
$diskUsed = [math]::Round($disk.Used / 1GB, 2)
$diskFree = [math]::Round($disk.Free / 1GB, 2)
$diskTotal = $diskUsed + $diskFree
$diskPercent = [math]::Round(($disk.Used / ($disk.Used + $disk.Free)) * 100, 1)

Write-Host "=== DISK ==="
Write-Host "Used: $diskUsed GB / Free: $diskFree GB / Total: $diskTotal GB / Percent: $diskPercent%"

# 系统内存
$os = Get-CimInstance Win32_OperatingSystem
$sysMemUsed = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 1)
$sysMemTotal = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
$sysMemPercent = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)

Write-Host ""
Write-Host "=== SYSTEM MEMORY ==="
Write-Host "Used: $sysMemUsed GB / Total: $sysMemTotal GB / Percent: $sysMemPercent%"

# Gateway进程
Write-Host ""
Write-Host "=== GATEWAY PROCESS ==="
$gw = Get-Process node -ErrorAction SilentlyContinue
if ($gw) {
    $gwMemory = [math]::Round(($gw.WorkingSet64 / 1MB), 1)
    $gwCpu = [math]::Round($gw.CPU, 2)
    Write-Host "Memory: $gwMemory MB | CPU: $gwCpu s | Processes: $($gw.Count)"
} else {
    Write-Host "No node process found"
}

# sessions.json大小
$sessionsPath = 'D:\OpenClaw\.openclaw\sessions.json'
if (Test-Path $sessionsPath) {
    $sessionsSize = [math]::Round((Get-Item $sessionsPath).Length / 1KB, 1)
    Write-Host ""
    Write-Host "=== SESSIONS ==="
    Write-Host "sessions.json size: $sessionsSize KB"
}

# 日志文件统计（最近4小时）
$logPath = 'D:\OpenClaw\.openclaw\logs'
$recentLogs = Get-ChildItem $logPath -Filter '*.log' -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-4) }
Write-Host ""
Write-Host "=== LOGS (last 4h) ==="
Write-Host "Recent log files: $($recentLogs.Count)"

# 输出JSON供后续解析
Write-Host ""
Write-Host "=== JSON OUTPUT ==="
$result = @{
    disk = @{
        usedGB = $diskUsed
        freeGB = $diskFree
        totalGB = $diskTotal
        percent = $diskPercent
    }
    memory = @{
        usedGB = $sysMemUsed
        totalGB = $sysMemTotal
        percent = $sysMemPercent
    }
    gateway = @{
        memoryMB = $gwMemory
        cpuS = $gwCpu
        processes = if($gw){$gw.Count}else{0}
    }
    sessionsSizeKB = $sessionsSize
    recentLogsCount = $recentLogs.Count
} | ConvertTo-Json -Compress
Write-Host $result