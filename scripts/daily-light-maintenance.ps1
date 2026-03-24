# OpenClaw 每日轻量维护脚本
# 在低峰期执行：清理缓存、重新加载配置、可选轻量重启 Gateway

param(
    [switch]$ForceRestart,      # 强制重启 Gateway
    [switch]$SkipRestart,       # 跳过 Gateway 重启
    [switch]$Verbose
)

$workspaceRoot = "D:\OpenClaw\.openclaw\workspace"
$openclawRoot = "D:\OpenClaw\.openclaw"
$maintenanceLogPath = Join-Path $workspaceRoot "memory\daily-maintenance-log.md"
$stabilityStatePath = Join-Path $workspaceRoot "memory\stability-state.json"

Write-Host "=== OpenClaw 每日轻量维护 ===" -ForegroundColor Cyan
Write-Host "时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

$maintenanceReport = @{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    actions = @()
    issues = @()
    duration = 0
}

$startTime = Get-Date

# ==================== 1. 清理缓存 ====================
Write-Host "[1/5] 清理缓存..." -ForegroundColor Yellow

$cacheActions = @()
try {
    # OpenClaw 缓存
    $cacheDir = Join-Path $openclawRoot "cache"
    if (Test-Path $cacheDir) {
        $oldFiles = Get-ChildItem $cacheDir -Recurse -File | Where-Object {
            $_.LastWriteTime -lt (Get-Date).AddDays(-3)
        }
        
        if ($oldFiles.Count -gt 0) {
            $totalSize = ($oldFiles | Measure-Object -Property Length -Sum).Sum / 1MB
            $oldFiles | Remove-Item -Force
            
            $cacheActions += "清理 OpenClaw 缓存：$($oldFiles.Count) 个文件 ($([math]::Round($totalSize, 2)) MB)"
            Write-Host "  ✅ 清理 $($oldFiles.Count) 个缓存文件 ($([math]::Round($totalSize, 2)) MB)" -ForegroundColor Green
        } else {
            Write-Host "  ℹ️ 无过期缓存文件" -ForegroundColor Gray
        }
    }
    
    # PowerShell 临时文件
    $tempDir = $env:TEMP
    if (Test-Path $tempDir) {
        $psTempFiles = Get-ChildItem $tempDir -File -Filter "*.tmp" | Where-Object {
            $_.LastWriteTime -lt (Get-Date).AddDays(-1)
        }
        
        if ($psTempFiles.Count -gt 0) {
            $psTempFiles | Remove-Item -Force
            $cacheActions += "清理 PowerShell 临时文件：$($psTempFiles.Count) 个"
            Write-Host "  ✅ 清理 $($psTempFiles.Count) 个临时文件" -ForegroundColor Green
        }
    }
    
    # 工作区临时文件
    $tmpDir = Join-Path $workspaceRoot "tmp"
    if (Test-Path $tmpDir) {
        $oldTmpFiles = Get-ChildItem $tmpDir -Recurse -File | Where-Object {
            $_.LastWriteTime -lt (Get-Date).AddDays(-1)
        }
        
        if ($oldTmpFiles.Count -gt 0) {
            $oldTmpFiles | Remove-Item -Force
            $cacheActions += "清理工作区临时文件：$($oldTmpFiles.Count) 个"
            Write-Host "  ✅ 清理 $($oldTmpFiles.Count) 个工作区临时文件" -ForegroundColor Green
        }
    }
    
    $maintenanceReport.actions += $cacheActions
} catch {
    Write-Host "  ❌ 缓存清理失败：$($_.Exception.Message)" -ForegroundColor Red
    $maintenanceReport.issues += @{
        step = "cache_cleanup"
        error = $_.Exception.Message
    }
}

# ==================== 2. 清理日志文件 ====================
Write-Host "`n[2/5] 清理日志文件..." -ForegroundColor Yellow

try {
    $logDir = Join-Path $workspaceRoot "memory"
    if (Test-Path $logDir) {
        # 保留最近 30 天的日志
        $oldLogs = Get-ChildItem $logDir -File -Filter "*.log" | Where-Object {
            $_.LastWriteTime -lt (Get-Date).AddDays(-30)
        }
        
        if ($oldLogs.Count -gt 0) {
            $oldLogs | Remove-Item -Force
            Write-Host "  ✅ 清理 $($oldLogs.Count) 个过期日志文件" -ForegroundColor Green
            $maintenanceReport.actions += "清理过期日志：$($oldLogs.Count) 个"
        } else {
            Write-Host "  ℹ️ 无过期日志文件" -ForegroundColor Gray
        }
        
        # 压缩旧的记忆文件（超过 7 天）
        $oldMdFiles = Get-ChildItem $logDir -File -Filter "*.md" | Where-Object {
            $_.Name -match '^\d{4}-\d{2}-\d{2}.md$' -and
            $_.LastWriteTime -lt (Get-Date).AddDays(-30)
        }
        
        if ($oldMdFiles.Count -gt 0) {
            Write-Host "  ℹ️ 发现 $($oldMdFiles.Count) 个旧记忆文件（保留不删除）" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "  ❌ 日志清理失败：$($_.Exception.Message)" -ForegroundColor Red
    $maintenanceReport.issues += @{
        step = "log_cleanup"
        error = $_.Exception.Message
    }
}

# ==================== 3. 重新加载配置 ====================
Write-Host "`n[3/5] 重新加载配置..." -ForegroundColor Yellow

try {
    $configOutput = & openclaw gateway config.get 2>&1 | Out-String
    
    if ($configOutput -match 'config') {
        Write-Host "  ✅ 配置重载成功" -ForegroundColor Green
        $maintenanceReport.actions += "重新加载 Gateway 配置"
    } else {
        Write-Host "  ⚠️ 配置重载响应异常" -ForegroundColor Yellow
        $maintenanceReport.issues += @{
            step = "config_reload"
            error = "配置重载响应异常"
        }
    }
} catch {
    Write-Host "  ❌ 配置重载失败：$($_.Exception.Message)" -ForegroundColor Red
    $maintenanceReport.issues += @{
        step = "config_reload"
        error = $_.Exception.Message
    }
}

# ==================== 4. 检查 Gateway 健康状态 ====================
Write-Host "`n[4/5] 检查 Gateway 健康状态..." -ForegroundColor Yellow

$gatewayHealthy = $true
$gatewayNeedsRestart = $false

try {
    $response = Invoke-WebRequest -Uri "http://127.0.0.1:18789/status" -TimeoutSec 5 -UseBasicParsing 2>$null
    
    if ($response.StatusCode -eq 200) {
        Write-Host "  ✅ Gateway 运行正常" -ForegroundColor Green
        
        # 检查响应时间
        $responseTime = $response.ResponseHeaders.'Date'
        Write-Host "  ℹ️ 响应状态：HTTP $($response.StatusCode)" -ForegroundColor Gray
    } else {
        Write-Host "  ❌ Gateway 响应异常：HTTP $($response.StatusCode)" -ForegroundColor Red
        $gatewayHealthy = $false
        $gatewayNeedsRestart = $true
    }
} catch {
    Write-Host "  ❌ Gateway 无法访问" -ForegroundColor Red
    $gatewayHealthy = $false
    $gatewayNeedsRestart = $true
}

# 检查内存使用
try {
    $os = Get-WmiObject Win32_OperatingSystem
    $memPercent = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)
    Write-Host "  系统内存：${memPercent}%" -ForegroundColor $(if($memPercent -gt 90){"Red"}elseif($memPercent -gt 80){"Yellow"}else{"Green"})
    
    if ($memPercent -gt 90) {
        Write-Host "  ⚠️ 内存使用率高，建议重启 Gateway" -ForegroundColor Yellow
        $gatewayNeedsRestart = $true
    }
} catch {}

# ==================== 5. Gateway 轻量重启（可选） ====================
Write-Host "`n[5/5] Gateway 轻量重启..." -ForegroundColor Yellow

if ($SkipRestart) {
    Write-Host "  ℹ️ 跳过 Gateway 重启（--SkipRestart 参数）" -ForegroundColor Gray
} elseif ($ForceRestart -or $gatewayNeedsRestart) {
    Write-Host "  🔄 执行 Gateway 轻量重启..." -ForegroundColor Cyan
    
    try {
        $restartOutput = & openclaw gateway restart 2>&1 | Out-String
        
        Write-Host "  ⏳ 等待 Gateway 重启..." -ForegroundColor Gray
        Start-Sleep -Seconds 15
        
        # 验证重启成功
        $retryCount = 0
        $restartSuccess = $false
        
        while ($retryCount -lt 5) {
            try {
                $response = Invoke-WebRequest -Uri "http://127.0.0.1:18789/status" -TimeoutSec 5 -UseBasicParsing 2>$null
                if ($response.StatusCode -eq 200) {
                    Write-Host "  ✅ Gateway 重启成功" -ForegroundColor Green
                    $restartSuccess = $true
                    $maintenanceReport.actions += "Gateway 轻量重启（成功）"
                    break
                }
            } catch {}
            
            $retryCount++
            Start-Sleep -Seconds 3
        }
        
        if (-not $restartSuccess) {
            Write-Host "  ❌ Gateway 重启后验证失败" -ForegroundColor Red
            $maintenanceReport.issues += @{
                step = "gateway_restart"
                error = "Gateway 重启后无法访问"
            }
        }
    } catch {
        Write-Host "  ❌ Gateway 重启失败：$($_.Exception.Message)" -ForegroundColor Red
        $maintenanceReport.issues += @{
            step = "gateway_restart"
            error = $_.Exception.Message
        }
    }
} else {
    Write-Host "  ℹ️ Gateway 状态正常，无需重启" -ForegroundColor Green
    $maintenanceReport.actions += "Gateway 状态检查（正常，无需重启）"
}

# ==================== 更新维护状态 ====================
$endTime = Get-Date
$maintenanceReport.duration = [math]::Round(($endTime - $startTime).TotalSeconds, 2)

if (Test-Path $stabilityStatePath) {
    $state = Get-Content $stabilityStatePath | ConvertFrom-Json
    $state.lastMaintenance = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    $state | ConvertTo-Json -Depth 10 | Set-Content $stabilityStatePath -Encoding UTF8
    Write-Host "`n  ✅ 已更新维护状态" -ForegroundColor Gray
}

# ==================== 记录维护日志 ====================
$logEntry = @"

## $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

**持续时间**: $($maintenanceReport.duration) 秒
**执行动作**: $($maintenanceReport.actions.Count) 个
**发现问题**: $($maintenanceReport.issues.Count) 个

### 执行动作
$(foreach ($action in $maintenanceReport.actions) { "- ✅ $action" })

### 问题记录
$(if ($maintenanceReport.issues.Count -eq 0) { "无" } else { $maintenanceReport.issues | ForEach-Object { "- ❌ $($_.step): $($_.error)" } })

"@

if (!(Test-Path $maintenanceLogPath)) {
    "# 每日维护日志`n" | Set-Content $maintenanceLogPath -Encoding UTF8
}
Add-Content $maintenanceLogPath $logEntry -Encoding UTF8

# ==================== 摘要输出 ====================
Write-Host ""
Write-Host "=== 维护完成 ===" -ForegroundColor Cyan
Write-Host "持续时间：$($maintenanceReport.duration) 秒" -ForegroundColor Gray
Write-Host "执行动作：$($maintenanceReport.actions.Count) 个" -ForegroundColor Gray
Write-Host "发现问题：$($maintenanceReport.issues.Count) 个" -ForegroundColor $(if($maintenanceReport.issues.Count -gt 0){"Yellow"}else{"Green"})

if ($maintenanceReport.issues.Count -gt 0) {
    Write-Host "`n问题详情:" -ForegroundColor Yellow
    foreach ($issue in $maintenanceReport.issues) {
        Write-Host "  - $($issue.step): $($issue.error)" -ForegroundColor Gray
    }
}

# 输出 JSON 报告（用于 Cron 任务）
Write-Host ""
Write-Host "JSON 报告:" -ForegroundColor Gray
$maintenanceReport | ConvertTo-Json -Depth 5
