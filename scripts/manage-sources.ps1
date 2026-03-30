#Requires -Version 5.1
<#
.SYNOPSIS
    信息源配置管理脚本
.DESCRIPTION
    管理 RSS 订阅源和关键词监控配置
.PARAMETER ListRSS
    列出所有 RSS 源
.PARAMETER AddRSS
    添加 RSS 源
.PARAMETER RemoveRSS
    删除 RSS 源
.PARAMETER EnableRSS
    启用 RSS 源
.PARAMETER DisableRSS
    禁用 RSS 源
.PARAMETER ListKeywords
    列出关键词配置
.PARAMETER AddKeyword
    添加关键词到目标
.PARAMETER RemoveKeyword
    从目标移除关键词
.PARAMETER AddTarget
    添加监控目标
.PARAMETER RemoveTarget
    移除监控目标
.PARAMETER EnableTarget
    启用监控目标
.PARAMETER DisableTarget
    禁用监控目标
.EXAMPLE
    .\manage-sources.ps1 -ListRSS
.EXAMPLE
    .\manage-sources.ps1 -AddRSS -Name "CAD教程" -Url "https://example.com/feed" -Keywords "AutoCAD,Revit"
.EXAMPLE
    .\manage-sources.ps1 -RemoveRSS -Name "CAD教程"
.EXAMPLE
    .\manage-sources.ps1 -ListKeywords
.EXAMPLE
    .\manage-sources.ps1 -AddKeyword -Target "GitHub CAD Search" -Keyword "Dynamo"
#>

param(
    [Parameter(ParameterSetName="RSS")]
    [switch]$ListRSS,

    [Parameter(ParameterSetName="AddRSS")]
    [string]$Name,

    [Parameter(ParameterSetName="AddRSS")]
    [string]$Url,

    [Parameter(ParameterSetName="AddRSS")]
    [string]$Keywords = "",

    [Parameter(ParameterSetName="AddRSS")]
    [switch]$Enabled = $true,

    [Parameter(ParameterSetName="RemoveRSS")]
    [string]$RemoveRSS,

    [Parameter(ParameterSetName="ToggleRSS")]
    [string]$EnableRSS,

    [Parameter(ParameterSetName="ToggleRSS")]
    [string]$DisableRSS,

    [Parameter(ParameterSetName="Keywords")]
    [switch]$ListKeywords,

    [Parameter(ParameterSetName="AddKeyword")]
    [string]$Target,

    [Parameter(ParameterSetName="AddKeyword")]
    [string]$Keyword,

    [Parameter(ParameterSetName="RemoveKeyword")]
    [string]$RemoveKeywordTarget,

    [Parameter(ParameterSetName="RemoveKeyword")]
    [string]$RemoveKeyword,

    [Parameter(ParameterSetName="AddTarget")]
    [string]$AddTargetName,

    [Parameter(ParameterSetName="AddTarget")]
    [string]$AddTargetUrl,

    [Parameter(ParameterSetName="AddTarget")]
    [string]$AddTargetKeywords = "",

    [Parameter(ParameterSetName="AddTarget")]
    [switch]$AddTargetEnabled = $true,

    [Parameter(ParameterSetName="RemoveTarget")]
    [string]$RemoveTarget,

    [Parameter(ParameterSetName="ToggleTarget")]
    [string]$EnableTarget,

    [Parameter(ParameterSetName="ToggleTarget")]
    [string]$DisableTarget,

    [Parameter(ParameterSetName="RunMonitors")]
    [switch]$RunRSS,

    [Parameter(ParameterSetName="RunMonitors")]
    [switch]$RunKeywords,

    [Parameter(ParameterSetName="RunMonitors")]
    [switch]$RunWebsite,

    [Parameter(ParameterSetName="RunMonitors")]
    [switch]$RunAll
)

$ErrorActionPreference = 'Continue'
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$RSS_CONFIG = Join-Path $SCRIPT_DIR "rss-sources.json"
$KW_CONFIG = Join-Path $SCRIPT_DIR "keyword-monitor-config.json"

# ==================== 辅助函数 ====================
function Get-JsonConfig([string]$Path) {
    if (-not (Test-Path $Path)) {
        Write-Error "配置文件不存在: $Path"
        return $null
    }
    return Get-Content $Path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Save-JsonConfig([string]$Path, [object]$Config) {
    $Config | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding UTF8 -NoNewline
    Write-Host "✅ 配置已保存: $Path" -ForegroundColor Green
}

function Write-MenuItem([string]$Label, [string]$Value, [string]$Color = "White") {
    Write-Host "  $Label" -ForegroundColor $Color -NoNewline
    Write-Host " : $Value"
}

function Parse-Keywords([string]$KeywordStr) {
    if ([string]::IsNullOrWhiteSpace($KeywordStr)) { return @() }
    return $KeywordStr -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
}

# ==================== RSS 操作 ====================
function Show-RSSList {
    $config = Get-JsonConfig $RSS_CONFIG
    if (-not $config) { return }

    Write-Host "`n📡 RSS 订阅源列表" -ForegroundColor Cyan
    Write-Host ("-" * 60)
    $sources = @($config.sources)
    if ($sources.Count -eq 0) {
        Write-Host "  (无配置)" -ForegroundColor DarkGray
        return
    }
    foreach ($s in $sources) {
        $status = if ($s.enabled) { "✅" } else { "❌" }
        $kws = if ($s.keywords) { $s.keywords -join ', ' } else { "(无)" }
        Write-Host "`n  [$status] $($s.name)" -ForegroundColor Yellow
        Write-MenuItem "  URL" $s.url "DarkGray"
        Write-MenuItem "  关键词" $kws "DarkGray"
        Write-MenuItem "  最大条目" $s.max_items "DarkGray"
    }
    Write-Host "`n共 $($sources.Count) 个源, $($sources.Where({$_.enabled}).Count) 个启用"
}

function Add-RSSSource {
    if ([string]::IsNullOrWhiteSpace($Name) -or [string]::IsNullOrWhiteSpace($Url)) {
        Write-Error "必须提供 -Name 和 -Url 参数"
        return
    }

    $config = Get-JsonConfig $RSS_CONFIG
    if (-not $config) { return }

    $keywords = Parse-Keywords $Keywords

    # 检查是否已存在
    $existing = $config.sources | Where-Object { $_.name -eq $Name }
    if ($existing) {
        Write-Error "RSS 源 '$Name' 已存在。使用 -RemoveRSS 删除后再添加，或修改现有配置。"
        return
    }

    $newSource = @{
        name = $Name
        url  = $Url
        keywords = $keywords
        enabled = [bool]$Enabled
        max_items = 10
    }

    $config.sources += $newSource
    Save-JsonConfig $RSS_CONFIG $config
    Write-Host "✅ 添加 RSS 源: $Name" -ForegroundColor Green
}

function Remove-RSSSource {
    if ([string]::IsNullOrWhiteSpace($RemoveRSS)) {
        Write-Error "必须提供 -RemoveRSS 参数"
        return
    }

    $config = Get-JsonConfig $RSS_CONFIG
    if (-not $config) { return }

    $initial = $config.sources.Count
    $config.sources = @($config.sources | Where-Object { $_.name -ne $RemoveRSS })

    if ($config.sources.Count -eq $initial) {
        Write-Error "未找到 RSS 源: $RemoveRSS"
        return
    }

    Save-JsonConfig $RSS_CONFIG $config
    Write-Host "✅ 删除 RSS 源: $RemoveRSS" -ForegroundColor Green
}

function Toggle-RSSEnabled {
    param([string]$TargetName, [bool]$Enabled)

    $config = Get-JsonConfig $RSS_CONFIG
    if (-not $config) { return }

    $source = $config.sources | Where-Object { $_.name -eq $TargetName } | Select-Object -First 1
    if (-not $source) {
        Write-Error "未找到 RSS 源: $TargetName"
        return
    }

    $source.enabled = $Enabled
    Save-JsonConfig $RSS_CONFIG $config
    $status = if ($Enabled) { "启用" } else { "禁用" }
    Write-Host "✅ RSS 源 '$TargetName' 已$status" -ForegroundColor Green
}

# ==================== 关键词操作 ====================
function Show-KeywordList {
    $config = Get-JsonConfig $KW_CONFIG
    if (-not $config) { return }

    Write-Host "`n🔍 关键词监控配置" -ForegroundColor Cyan
    Write-Host ("-" * 60)
    $targets = @($config.targets)
    if ($targets.Count -eq 0) {
        Write-Host "  (无配置)" -ForegroundColor DarkGray
        return
    }
    foreach ($t in $targets) {
        $status = if ($t.enabled) { "✅" } else { "❌" }
        $kws = if ($t.keywords) { $t.keywords -join ', ' } else { "(无)" }
        Write-Host "`n  [$status] $($t.name)" -ForegroundColor Yellow
        Write-MenuItem "  URL" $t.url "DarkGray"
        Write-MenuItem "  关键词" $kws "DarkGray"
        Write-MenuItem "  最低匹配度" $t.min_relevance "DarkGray"
        Write-MenuItem "  类型" $t.type "DarkGray"
    }
    Write-Host "`n更新间隔: $($config.update_interval_hours) 小时"
    Write-Host "共 $($targets.Count) 个目标, $($targets.Where({$_.enabled}).Count) 个启用"
}

function Add-Keyword {
    if ([string]::IsNullOrWhiteSpace($Target) -or [string]::IsNullOrWhiteSpace($Keyword)) {
        Write-Error "必须提供 -Target 和 -Keyword 参数"
        return
    }

    $config = Get-JsonConfig $KW_CONFIG
    if (-not $config) { return }

    $target = $config.targets | Where-Object { $_.name -eq $Target } | Select-Object -First 1
    if (-not $target) {
        Write-Error "未找到监控目标: $Target`n使用 -AddTarget 添加新目标"
        return
    }

    if ($Keyword -notin $target.keywords) {
        $target.keywords += $Keyword
        Save-JsonConfig $KW_CONFIG $config
        Write-Host "✅ 添加关键词 '$Keyword' 到 '$Target'" -ForegroundColor Green
    } else {
        Write-Host "关键词 '$Keyword' 已存在于 '$Target'" -ForegroundColor Yellow
    }
}

function Remove-Keyword {
    if ([string]::IsNullOrWhiteSpace($RemoveKeywordTarget) -or [string]::IsNullOrWhiteSpace($RemoveKeyword)) {
        Write-Error "必须提供 -RemoveKeywordTarget 和 -RemoveKeyword 参数"
        return
    }

    $config = Get-JsonConfig $KW_CONFIG
    if (-not $config) { return }

    $target = $config.targets | Where-Object { $_.name -eq $RemoveKeywordTarget } | Select-Object -First 1
    if (-not $target) {
        Write-Error "未找到监控目标: $RemoveKeywordTarget"
        return
    }

    $initial = $target.keywords.Count
    $target.keywords = @($target.keywords | Where-Object { $_ -ne $RemoveKeyword })

    if ($target.keywords.Count -eq $initial) {
        Write-Error "关键词 '$RemoveKeyword' 不存在于 '$RemoveKeywordTarget'"
        return
    }

    Save-JsonConfig $KW_CONFIG $config
    Write-Host "✅ 从 '$RemoveKeywordTarget' 移除关键词 '$RemoveKeyword'" -ForegroundColor Green
}

function Add-MonitorTarget {
    if ([string]::IsNullOrWhiteSpace($AddTargetName) -or [string]::IsNullOrWhiteSpace($AddTargetUrl)) {
        Write-Error "必须提供 -AddTargetName 和 -AddTargetUrl 参数"
        return
    }

    $config = Get-JsonConfig $KW_CONFIG
    if (-not $config) { return }

    $existing = $config.targets | Where-Object { $_.name -eq $AddTargetName }
    if ($existing) {
        Write-Error "目标 '$AddTargetName' 已存在"
        return
    }

    $newTarget = @{
        name = $AddTargetName
        url = $AddTargetUrl
        keywords = Parse-Keywords $AddTargetKeywords
        min_relevance = 0.5
        enabled = [bool]$AddTargetEnabled
        type = "generic"
    }

    $config.targets += $newTarget
    Save-JsonConfig $KW_CONFIG $config
    Write-Host "✅ 添加监控目标: $AddTargetName" -ForegroundColor Green
}

function Remove-MonitorTarget {
    if ([string]::IsNullOrWhiteSpace($RemoveTarget)) {
        Write-Error "必须提供 -RemoveTarget 参数"
        return
    }

    $config = Get-JsonConfig $KW_CONFIG
    if (-not $config) { return }

    $initial = $config.targets.Count
    $config.targets = @($config.targets | Where-Object { $_.name -ne $RemoveTarget })

    if ($config.targets.Count -eq $initial) {
        Write-Error "未找到监控目标: $RemoveTarget"
        return
    }

    Save-JsonConfig $KW_CONFIG $config
    Write-Host "✅ 删除监控目标: $RemoveTarget" -ForegroundColor Green
}

function Toggle-TargetEnabled {
    param([string]$TargetName, [bool]$Enabled)

    $config = Get-JsonConfig $KW_CONFIG
    if (-not $config) { return }

    $target = $config.targets | Where-Object { $_.name -eq $TargetName } | Select-Object -First 1
    if (-not $target) {
        Write-Error "未找到监控目标: $TargetName"
        return
    }

    $target.enabled = $Enabled
    Save-JsonConfig $KW_CONFIG $config
    $status = if ($Enabled) { "启用" } else { "禁用" }
    Write-Host "✅ 监控目标 '$TargetName' 已$status" -ForegroundColor Green
}

# ==================== 运行监控 ====================
function Invoke-Monitor {
    param([string]$ScriptName, [string]$Title)

    $scriptPath = Join-Path $SCRIPT_DIR $ScriptName
    if (-not (Test-Path $scriptPath)) {
        Write-Error "脚本不存在: $scriptPath"
        return
    }

    Write-Host "`n🚀 运行 $Title ..." -ForegroundColor Cyan
    python $scriptPath
}

# ==================== 主程序 ====================
Write-Host ""

if ($ListRSS) {
    Show-RSSList
}
elseif (-not [string]::IsNullOrWhiteSpace($AddRSS)) {
    Add-RSSSource
}
elseif (-not [string]::IsNullOrWhiteSpace($RemoveRSS)) {
    Remove-RSSSource
}
elseif (-not [string]::IsNullOrWhiteSpace($EnableRSS)) {
    Toggle-RSSEnabled -TargetName $EnableRSS -Enabled $true
}
elseif (-not [string]::IsNullOrWhiteSpace($DisableRSS)) {
    Toggle-RSSEnabled -TargetName $DisableRSS -Enabled $false
}
elseif ($ListKeywords) {
    Show-KeywordList
}
elseif (-not [string]::IsNullOrWhiteSpace($Target) -and -not [string]::IsNullOrWhiteSpace($Keyword)) {
    Add-Keyword
}
elseif (-not [string]::IsNullOrWhiteSpace($RemoveKeywordTarget) -and -not [string]::IsNullOrWhiteSpace($RemoveKeyword)) {
    Remove-Keyword
}
elseif (-not [string]::IsNullOrWhiteSpace($AddTargetName)) {
    Add-MonitorTarget
}
elseif (-not [string]::IsNullOrWhiteSpace($RemoveTarget)) {
    Remove-MonitorTarget
}
elseif (-not [string]::IsNullOrWhiteSpace($EnableTarget)) {
    Toggle-TargetEnabled -TargetName $EnableTarget -Enabled $true
}
elseif (-not [string]::IsNullOrWhiteSpace($DisableTarget)) {
    Toggle-TargetEnabled -TargetName $DisableTarget -Enabled $false
}
elseif ($RunRSS) {
    Invoke-Monitor "rss-monitor.py" "RSS 监控"
}
elseif ($RunKeywords) {
    Invoke-Monitor "keyword-monitor.py" "关键词监控"
}
elseif ($RunWebsite) {
    Invoke-Monitor "website-monitor.py" "网站监控"
}
elseif ($RunAll) {
    Invoke-Monitor "website-monitor.py" "网站监控"
    Invoke-Monitor "rss-monitor.py" "RSS 监控"
    Invoke-Monitor "keyword-monitor.py" "关键词监控"
}
else {
    Write-Host @"
📋 信息源管理脚本

用法:
  RSS 管理:
    .\manage-sources.ps1 -ListRSS
    .\manage-sources.ps1 -AddRSS -Name "xxx" -Url "..." -Keywords "kw1,kw2"
    .\manage-sources.ps1 -RemoveRSS -Name "xxx"
    .\manage-sources.ps1 -EnableRSS -Name "xxx"
    .\manage-sources.ps1 -DisableRSS -Name "xxx"

  关键词监控管理:
    .\manage-sources.ps1 -ListKeywords
    .\manage-sources.ps1 -AddKeyword -Target "xxx" -Keyword "yyy"
    .\manage-sources.ps1 -RemoveKeyword -RemoveKeywordTarget "xxx" -RemoveKeyword "yyy"
    .\manage-sources.ps1 -AddTarget -AddTargetName "xxx" -AddTargetUrl "..."
    .\manage-sources.ps1 -RemoveTarget -RemoveTarget "xxx"
    .\manage-sources.ps1 -EnableTarget -EnableTarget "xxx"
    .\manage-sources.ps1 -DisableTarget -DisableTarget "xxx"

  运行监控:
    .\manage-sources.ps1 -RunRSS
    .\manage-sources.ps1 -RunKeywords
    .\manage-sources.ps1 -RunWebsite
    .\manage-sources.ps1 -RunAll

"@ -ForegroundColor Cyan
}
