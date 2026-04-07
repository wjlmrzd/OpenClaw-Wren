# Gateway Memory Monitor - 定时记录内存趋势
param(
    [int]$IntervalSeconds = 300,  # 默认 5 分钟检查一次
    [int]$MemoryThresholdMB = 400,  # 内存阈值，超过则告警
    [string]$LogFile = "D:\OpenClaw\.openclaw\workspace\memory\gateway-memory-trend.json"
)

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$nodeProcs = Get-Process -Name node -ErrorAction SilentlyContinue | Where-Object { $_.StartTime -gt (Get-Date).AddHours(-24) }

if ($nodeProcs) {
    $maxMem = ($nodeProcs | Measure-Object WorkingSet64 -Maximum).Maximum
    $maxMemMB = [math]::Round($maxMem / 1MB, 2)
    $totalMem = [math]::Round(($nodeProcs | Measure-Object WorkingSet64 -Sum).Sum / 1MB, 2)
    
    $entry = @{
        timestamp = $timestamp
        maxMemoryMB = $maxMemMB
        totalMemoryMB = $totalMem
        processCount = $nodeProcs.Count
        pids = @($nodeProcs.Id)
    }
    
    # 读取现有日志
    $existingData = @()
    if (Test-Path $LogFile) {
        try {
            $existingData = Get-Content $LogFile -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($existingData -isnot [array]) { $existingData = @($existingData) }
        } catch { $existingData = @() }
    }
    
    # 只保留最近 24 小时的数据 (约 288 条/5分钟)
    $existingData = $existingData | Where-Object { 
        try { (Get-Date $_.timestamp) -gt (Get-Date).AddHours(-24) } catch { $false }
    }
    
    # 添加新记录
    $existingData += $entry
    
    # 保存
    $existingData | ConvertTo-Json -Depth 10 | Set-Content $LogFile -Encoding UTF8
    
    Write-Host "[$timestamp] Gateway Memory: ${maxMemMB}MB (threshold: ${MemoryThresholdMB}MB)"
    
    # 如果超过阈值，输出告警标记
    if ($maxMemMB -gt $MemoryThresholdMB) {
        Write-Host "ALERT: Memory exceeds threshold!"
        exit 1
    }
} else {
    Write-Host "[$timestamp] No Gateway process found"
}