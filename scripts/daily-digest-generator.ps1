#Requires -Version 5.1
<#
.SYNOPSIS
    每日信息汇总报告生成器
.DESCRIPTION
    整合 RSS 更新、关键词监控、网站变化，生成统一的信息日报
#>

param(
    [switch]$NoRSS,
    [switch]$NoKeywords,
    [switch]$NoWebsite,
    [switch]$Quiet
)

$ErrorActionPreference = 'Continue'
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$OUT_DIR = $SCRIPT_DIR

# ==================== 颜色定义 ====================
function Write-Section([string]$Title, [string]$Color = "Cyan") {
    $esc = [char]27
    Write-Host "$esc[96m$Title$esc[0m"
}

function Write-Item([string]$Text) {
    Write-Host "  $Text"
}

# ==================== 读取数据源 ====================
function Get-RSSData {
    $jsonPath = Join-Path $SCRIPT_DIR "rss-monitor-output.json"
    if (-not (Test-Path $jsonPath)) {
        if (-not $script:Quiet) { Write-Host "  (无 RSS 数据)" -ForegroundColor DarkGray }
        return $null
    }
    try {
        $data = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        return $data
    } catch {
        if (-not $script:Quiet) { Write-Host "  读取 RSS 数据失败: $_" -ForegroundColor Yellow }
        return $null
    }
}

function Get-KeywordData {
    $jsonPath = Join-Path $SCRIPT_DIR "keyword-monitor-output.json"
    if (-not (Test-Path $jsonPath)) {
        if (-not $script:Quiet) { Write-Host "  (无关键词监控数据)" -ForegroundColor DarkGray }
        return $null
    }
    try {
        $data = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        return $data
    } catch {
        if (-not $script:Quiet) { Write-Host "  读取关键词数据失败: $_" -ForegroundColor Yellow }
        return $null
    }
}

function Get-WebsiteData {
    $jsonPath = Join-Path $SCRIPT_DIR "website-monitor-state.json"
    if (-not (Test-Path $jsonPath)) {
        if (-not $script:Quiet) { Write-Host "  (无网站监控数据)" -ForegroundColor DarkGray }
        return $null
    }
    try {
        $data = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        return $data
    } catch {
        if (-not $script:Quiet) { Write-Host "  读取网站监控数据失败: $_" -ForegroundColor Yellow }
        return $null
    }
}

# ==================== 格式化输出 ====================
function Format-Digest {
    param(
        [PSObject]$RSSData,
        [PSObject]$KeywordData,
        [PSObject]$WebsiteData
    )

    $dateStr = Get-Date -Format "yyyy-MM-dd"
    $timeStr = Get-Date -Format "HH:mm"

    $lines = @()
    $lines += "📊 信息日报 - $dateStr"
    $lines += ""

    # --- RSS 订阅 ---
    if ($RSSData -and -not $script:NoRSS) {
        $entries = @($RSSData.entries)
        if ($entries.Count -gt 0) {
            $lines += "🔹 RSS 订阅 ($($entries.Count) 条更新)"
            $srcGroups = $entries | Group-Object source
            foreach ($src in $srcGroups) {
                $srcName = $src.Name
                $srcEntries = $src.Group | Select-Object -First 5
                $lines += "  📁 $srcName"
                for ($i = 0; $i -lt $srcEntries.Count; $i++) {
                    $e = $srcEntries[$i]
                    $title = if ($e.title.Length -gt 60) { $e.title.Substring(0, 60) + "..." } else { $e.title }
                    $summary = if ($e.summary -and $e.summary.Length -gt 50) { $e.summary.Substring(0, 50) + "..." } else { $e.summary }
                    $lines += "  $($i+1). $title"
                    if ($summary) { $lines += "     💬 $summary" }
                    if ($e.keywords -and $e.keywords.Count -gt 0) { $lines += "     🔑 $($e.keywords -join ', ')" }
                }
            }
        } else {
            $lines += "🔹 RSS 订阅 (0 条更新) 🎉"
        }
    }

    # --- 关键词监控 ---
    if ($KeywordData -and -not $script:NoKeywords) {
        $results = @($KeywordData.results)
        $totalNew = ($results | ForEach-Object { @($_.new_items).Count } | Measure-Object -Sum).Sum
        if ($totalNew -gt 0) {
            $lines += ""
            $lines += "🔹 关键词监控 ($totalNew 条新发现)"
            foreach ($r in $results) {
                $items = @($r.new_items)
                if ($items.Count -eq 0) { continue }
                $lines += "  📁 $($r.name) ($($items.Count) 条)"
                for ($i = 0; $i -lt $items.Count; $i++) {
                    $item = $items[$i]
                    $title = if ($item.title.Length -gt 60) { $item.title.Substring(0, 60) + "..." } else { $item.title }
                    $score = $item.score
                    $kws = $item.keywords_matched -join ', '
                    $lines += "  $($i+1). $title"
                    if ($kws) { $lines += "     🔑 $kws (匹配度: $score)" }
                }
            }
        } else {
            $lines += ""
            $lines += "🔹 关键词监控 (0 条新发现) 🎉"
        }
    }

    # --- 网站更新 ---
    if ($WebsiteData -and -not $script:NoWebsite) {
        $sites = $WebsiteData.websites.PSObject.Properties
        $updatedCount = 0
        $updateLines = @()
        foreach ($site in $sites) {
            $siteName = $site.Name
            $siteInfo = $site.Value
            if ($siteInfo.last_change) {
                $updatedCount++
                $change = $siteInfo.last_change
                $changeDesc = if ($change.Length -gt 60) { $change.Substring(0, 60) + "..." } else { $change }
                $updateLines += "  • $siteName - $changeDesc"
            }
        }
        if ($updatedCount -gt 0) {
            $lines += ""
            $lines += "🔹 网站更新 ($updatedCount 条)"
            $lines += $updateLines
        } else {
            $lines += ""
            $lines += "🔹 网站更新 (0 条) 🎉"
        }
    }

    $lines += ""
    $lines += "发送时间: $timeStr"

    return $lines -join "`n"
}

# ==================== 主程序 ====================
if (-not $Quiet) {
    Write-Host ""
    Write-Section "📰 每日信息汇总报告生成器"
    Write-Host ""
}

$rssData = Get-RSSData
$kwData = Get-KeywordData
$webData = Get-WebsiteData

$digest = Format-Digest -RSSData $rssData -KeywordData $kwData -WebsiteData $webData

if (-not $Quiet) {
    Write-Host $digest
}

# 保存到文件
$outFile = Join-Path $OUT_DIR "daily-digest.txt"
$digest | Out-File -FilePath $outFile -Encoding UTF8

# 输出 JSON（供外部使用）
$outJson = @{
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    date = (Get-Date -Format "yyyy-MM-dd")
    rss_count = if ($rssData) { @($rssData.entries).Count } else { 0 }
    keyword_count = if ($kwData) { ($kwData.results | ForEach-Object { @($_.new_items).Count } | Measure-Object -Sum).Sum } else { 0 }
    website_count = if ($webData) { @($webData.websites.PSObject.Properties | Where-Object { $_.Value.last_change }).Count } else { 0 }
    digest_text = $digest
} | ConvertTo-Json -Depth 5 -Compress

$jsonFile = Join-Path $OUT_DIR "daily-digest.json"
$outJson | Out-File -FilePath $jsonFile -Encoding UTF8

if (-not $Quiet) {
    Write-Host ""
    Write-Host "输出文件:"
    Write-Host "  文本: $outFile"
    Write-Host "  JSON: $jsonFile"
    Write-Host ""
}

# 返回摘要供管道使用
return $digest
