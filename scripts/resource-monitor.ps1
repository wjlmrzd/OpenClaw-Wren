# Resource Monitor Script
# Collects system resource usage and API quota information

param(
    [string]$OutputFormat = "text"  # text or json
)

# Mock data for demonstration (in real implementation, this would collect actual metrics)
$mockData = @{
    models = @{
        'qwen3.5-plus' = @{ requests = 45; quota = 50 }
        'glm-5' = @{ requests = 32; quota = 50 }
        'qwen3-coder-plus' = @{ requests = 28; quota = 50 }
    }
    system = @{
        memory = 85
        cpu = 45
        disk = 78
    }
    quotaLimit = 50  # per hour
}

if ($OutputFormat -eq "json") {
    $mockData | ConvertTo-Json -Depth 3
    return
}

# Generate human-readable report
Write-Output "📊 **资源使用仪表板**"
Write-Output ""
Write-Output "**模型配额使用情况**："

foreach ($modelEntry in $mockData.models.GetEnumerator()) {
    $model = $modelEntry.Key
    $data = $modelEntry.Value
    $percent = [math]::Round(($data.requests / $mockData.quotaLimit) * 100)
    
    $indicator = "🟢"
    if ($percent -gt 80) { $indicator = "🟡" }
    if ($percent -gt 90) { $indicator = "🔴" }
    
    Write-Output "- $model`: $data.requests/$($mockData.quotaLimit) ($percent% $indicator)"
}

Write-Output ""
Write-Output "**系统资源**："
Write-Output "- 内存: $($mockData.system.memory)% $(if ($mockData.system.memory -gt 90) { "🟡" } else { "🟢" })"
Write-Output "- CPU: $($mockData.system.cpu)% $(if ($mockData.system.cpu -gt 80) { "🟡" } else { "🟢" })"
Write-Output "- 磁盘: $($mockData.system.disk)% $(if ($mockData.system.disk -gt 85) { "🟡" } else { "🟢" })"

# Check for warnings
$warnings = @()

foreach ($modelEntry in $mockData.models.GetEnumerator()) {
    $model = $modelEntry.Key
    $data = $modelEntry.Value
    $percent = [math]::Round(($data.requests / $mockData.quotaLimit) * 100)
    
    if ($percent -gt 80 -and $percent -le 90) {
        $warnings += "$model 模型请求量 $percent% (接近配额限制)"
    } elseif ($percent -gt 90) {
        $warnings += "$model 模型请求量 $percent% (严重接近配额限制)"
    }
}

if ($mockData.system.memory -gt 90) {
    $warnings += "内存使用率 $($mockData.system.memory)% (建议重启 Gateway)"
}
if ($mockData.system.disk -gt 85) {
    $warnings += "磁盘使用率 $($mockData.system.disk)% (触发日志清理)"
}

if ($warnings.Count -gt 0) {
    Write-Output ""
    Write-Output "⚠️ **预警信息**："
    foreach ($warning in $warnings) {
        Write-Output "- $warning"
    }
} else {
    Write-Output ""
    Write-Output "✅ **系统状态**：正常"
}

Write-Output ""
Write-Output "💡 **优化建议**："
Write-Output "- 监控模型请求频率，避免集中调用"
Write-Output "- 定期清理日志文件释放磁盘空间" 
Write-Output "- 如内存持续高位，考虑重启 Gateway"