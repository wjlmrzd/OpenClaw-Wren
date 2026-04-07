<#
cost-tracker-scan.ps1
从 session 文件中提取 usage 数据并写入 cost-tracker store

工作原理：
1. 扫描所有活跃 session 文件 (main/sessions/)
2. 解析每个 session 中 type="message" 且 role="assistant" 的条目
3. 提取 usage 数据 (input/output/totalTokens)
4. 调用 cost-tracker 的 Python 模块记录
5. 避免重复记录（通过已记录 session key 列表）
#>

$ErrorActionPreference = "Stop"
$repo = "D:\OpenClaw\.openclaw\workspace"
$storeDir = "$repo\memory\cost-tracker"
$storeFile = "$storeDir\store.json"
$mainSessionsDir = "D:\OpenClaw\.openclaw\agents\main\sessions"

# ── 读取已知记录 ───────────────────────────────────────────
if (-not (Test-Path $storeFile)) {
    $store = @{
        sessions = @{}
        globalTotal = @{
            totalCalls = 0
            totalTokens = 0
            totalCost = 0.0
        }
        trackedFiles = @{}  # sessionFile -> lastProcessedLine
    }
} else {
    try {
        $store = Get-Content $storeFile -Raw | ConvertFrom-Json
        if (-not $store.trackedFiles) { 
        $store | Add-Member -NotePropertyName "trackedFiles" -NotePropertyValue (@{}) -Force
    }
    } catch {
        Write-Host "[CostTracker] Failed to read store: $_"
        exit 0
    }
}

# ── 定价表（与 src/cost-tracker/pricing.ts 保持一致）───────
# DashScope: qwen3.5-plus = $0.2/$0.6 per 1M tokens
# MiniMax 2.7: 免费
# 其他: 免费
function Get-CallCost {
    param([string]$model, [long]$inputTok, [long]$outputTok)
    
    $modelLower = $model.ToLower()
    
    # Anthropic
    if ($modelLower -match "opus-4") { $in = 15; $out = 75 }
    elseif ($modelLower -match "sonnet-4") { $in = 3; $out = 15 }
    elseif ($modelLower -match "haiku-4") { $in = 0.8; $out = 4 }
    # OpenAI
    elseif ($modelLower -match "gpt-4o-mini") { $in = 0.15; $out = 0.6 }
    elseif ($modelLower -match "gpt-4o") { $in = 2.5; $out = 10 }
    # DashScope
    elseif ($modelLower -match "qwen3.5-plus") { $in = 0.2; $out = 0.6 }
    elseif ($modelLower -match "qwen3-coder-plus") { $in = 0.4; $out = 1.2 }
    elseif ($modelLower -match "qwen3-coder-next") { $in = 0.8; $out = 2.0 }
    elseif ($modelLower -match "glm-5") { $in = 0.1; $out = 0.3 }
    elseif ($modelLower -match "glm-4.7") { $in = 0.1; $out = 0.3 }
    elseif ($modelLower -match "kimi-k2") { $in = 0.5; $out = 1.5 }
    # MiniMax / 免费模型
    elseif ($modelLower -match "minimax" -or $modelLower -match "free" -or $modelLower -match "coding-plan") {
        return @{ cost = 0.0; isFree = $true }
    }
    else { return @{ cost = -1.0; isFree = $false } }
    
    $cost = ($inputTok / 1000000 * $in) + ($outputTok / 1000000 * $out)
    return @{ cost = $cost; isFree = $false }
}

# ── 扫描 session 文件 ───────────────────────────────────────
$sessionFiles = Get-ChildItem $mainSessionsDir -Filter "*.jsonl" | Sort-Object LastWriteTime -Descending

$newCalls = 0
$newTokens = 0
$newCost = 0.0

foreach ($sf in $sessionFiles) {
    $filePath = $sf.FullName
    
    # 获取上次处理到第几行
    $lastLine = $store.trackedFiles.$filePath
    $startLine = if ($lastLine) { [int]$lastLine } else { 0 }
    
    # 读取文件所有行
    $allLines = @()
    try {
        $allLines = Get-Content $filePath -Encoding UTF8
    } catch {
        continue
    }
    
    if ($allLines.Count -le $startLine) { continue }
    
    $lineIdx = 0
    foreach ($line in $linesToProcess) {
        $lineIdx += 1
        if (-not $line.Trim()) { continue }
        
        try {
            $entry = $line | ConvertFrom-Json
            
            # 只处理 assistant 消息
            if ($entry.type -ne "message") { continue }
            if ($entry.message.role -ne "assistant") { continue }
            
            $msg = $entry.message
            $usage = $msg.usage
            if (-not $usage) { continue }
            
            $inputTok = [long]($usage.input ?? 0)
            $outputTok = [long]($usage.output ?? 0)
            $totalTok = [long]($usage.totalTokens ?? 0)
            $provider = $msg.provider ?? "unknown"
            $model = $msg.model ?? "unknown"
            
            # 跳过无效或零使用
            if ($inputTok -eq 0 -and $outputTok -eq 0) { continue }
            
            # 计算费用
            $costInfo = Get-CallCost -model $model -inputTok $inputTok -outputTok $outputTok
            
            # 构建 call ID（防止重复）
            $callId = "$($entry.id)-$inputTok-$outputTok"
            
            # 获取 session key（从文件路径推断）
            $sessionKey = $sf.Name -replace '\.jsonl$', ''
            if ($sessionKey -match "-topic-(\d+)$") {
                $topicId = $matches[1]
                # 这是一个 topic session
            }
            
            # 写入 session 记录
            $sessionKey = $sf.Name -replace '\.jsonl$', ''
            if (-not $store.sessions.$sessionKey) {
                $store.sessions.$sessionKey = @{
                    sessionKey = $sessionKey
                    totalCalls = 0
                    totalTokens = 0
                    totalCost = 0.0
                    isFree = $true
                    calls = @()
                }
            }
            
            $s = $store.sessions.$sessionKey
            $s.totalCalls += 1
            $effectiveTokens = if ($totalTok -gt 0) { $totalTok } else { $inputTok + $outputTok }
            $s.totalTokens += $effectiveTokens
            $s.totalCost += $costInfo.cost
            $s.isFree = $s.isFree -and $costInfo.isFree
            
            $store.globalTotal.totalCalls += 1
            $store.globalTotal.totalTokens += $effectiveTokens
            $store.globalTotal.totalCost += $costInfo.cost
            
            $newCalls += 1
            $newTokens += $effectiveTokens
            $newCost += $costInfo.cost
            
            # 更新追踪位置
            $store.trackedFiles.$filePath = [string]($startLine + $lineIdx)
            
        } catch {
            # 跳过无法解析的行
        }
    }
}

# ── 保存结果 ───────────────────────────────────────────────
if ($newCalls -gt 0) {
    try {
        if (-not (Test-Path $storeDir)) {
            New-Item -ItemType Directory -Force -Path $storeDir | Out-Null
        }
        
        # 清理过于古老的 session（只保留最近 30 个 session 的详细记录）
        $allSessions = @($store.sessions.PSObject.Properties | Sort-Object Value.totalCost -Descending)
        if ($allSessions.Count -gt 30) {
            $toRemove = $allSessions | Select-Object -Skip 30
            foreach ($r in $toRemove) {
                $store.sessions.PSObject.Properties.Remove($r.Name)
            }
        }
        
        $store | ConvertTo-Json -Depth 10 | Set-Content $storeFile -Encoding UTF8
        Write-Host "[CostTracker] Scanned $($sessionFiles.Count) session files"
        Write-Host "[CostTracker] New: $($newCalls) calls, $($newTokens.ToString('N0')) tokens, `$$($newCost.ToString('F6'))"
        Write-Host "[CostTracker] Global total: $($store.globalTotal.totalCalls) calls, `$$($store.globalTotal.totalCost.ToString('F6'))"
    } catch {
        Write-Host "[CostTracker] Failed to save store: $_"
    }
} else {
    Write-Host "[CostTracker] No new usage records found."
}
