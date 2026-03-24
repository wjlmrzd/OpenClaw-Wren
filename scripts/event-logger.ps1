# Event Logger - 事件日志记录器
# 用于 OpenClaw 自治系统的事件收集和状态追踪

param(
    [Parameter(Mandatory=$true)]
    [string]$EventType,
    
    [Parameter(Mandatory=$true)]
    [string]$Message,
    
    [ValidateSet("success", "warning", "error", "info")]
    [string]$Level = "info",
    
    [string]$Source = "unknown",
    
    [hashtable]$Metadata = @{}
)

$workspaceRoot = "D:\OpenClaw\.openclaw\workspace"
$eventsLogPath = Join-Path $workspaceRoot "memory\events.log"
$eventsStatePath = Join-Path $workspaceRoot "memory\events-state.json"

# 确保目录存在
$logDir = Split-Path $eventsLogPath -Parent
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
}

# 创建事件对象
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
$timestampUnix = [int][double]::Parse((Get-Date -UFormat %s))

$event = [PSCustomObject]@{
    ts = $timestamp
    tsUnix = $timestampUnix
    type = $EventType
    level = $Level
    source = $Source
    message = $Message
    metadata = $Metadata
}

# 转换为 JSON 并追加到日志文件
$eventJson = $event | ConvertTo-Json -Compress
Add-Content -Path $eventsLogPath -Value $eventJson

# 更新状态文件
$state = @{
    lastEventTs = $timestamp
    lastEventUnix = $timestampUnix
    totalEvents = 0
    eventsByType = @{}
    eventsByLevel = @{
        success = 0
        warning = 0
        error = 0
        info = 0
    }
}

# 读取现有状态
if (Test-Path $eventsStatePath) {
    try {
        $existingState = Get-Content $eventsStatePath -Raw | ConvertFrom-Json
        $state.totalEvents = $existingState.totalEvents + 1
        $state.eventsByType = $existingState.eventsByType | ConvertTo-HashTable
        $state.eventsByLevel = $existingState.eventsByLevel | ConvertTo-HashTable
    } catch {
        $state.totalEvents = 1
    }
} else {
    $state.totalEvents = 1
}

# 更新事件类型计数
if ($state.eventsByType.ContainsKey($EventType)) {
    $state.eventsByType[$EventType] = $state.eventsByType[$EventType] + 1
} else {
    $state.eventsByType[$EventType] = 1
}

# 更新事件级别计数
if ($state.eventsByLevel.ContainsKey($Level)) {
    $state.eventsByLevel[$Level] = $state.eventsByLevel[$Level] + 1
}

# 保存状态
$state | ConvertTo-Json -Depth 10 | Set-Content -Path $eventsStatePath

# 输出结果
Write-Output "Event logged: $EventType [$Level] - $Message"
Write-Output "Total events: $($state.totalEvents)"
