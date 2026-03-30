# 信息采集模块 - RSS、关键词、网站监控
# 由 unified-maintenance-console.ps1 调用

$ErrorActionPreference = "Continue"

$DataDir = Join-Path $env:USERPROFILE ".openclaw\data"
$FeedsDir = Join-Path $DataDir "feeds"
$KeywordsDir = Join-Path $DataDir "keywords"

function Show-InfoCollectorMenu {
    Clear-Host
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗"
    Write-Host "║                  信息采集 v1.0                                 ║"
    Write-Host "╠══════════════════════════════════════════════════════════════╣"
    Write-Host "║  📰 RSS 阅读                                                   ║"
    Write-Host "║  1. 添加 RSS 源                                                ║"
    Write-Host "║  2. 查看 RSS 列表                                              ║"
    Write-Host "║  3. 读取订阅内容                                                ║"
    Write-Host "║  4. 删除 RSS 源                                                ║"
    Write-Host "╠══════════════════════════════════════════════════════════════╣"
    Write-Host "║  🔍 关键词监控                                                  ║"
    Write-Host "║  5. 添加关键词                                                  ║"
    Write-Host "║  6. 查看关键词列表                                              ║"
    Write-Host "║  7. 执行关键词搜索                                              ║"
    Write-Host "║  8. 删除关键词                                                  ║"
    Write-Host "╠══════════════════════════════════════════════════════════════╣"
    Write-Host "║  🌐 网站监控                                                   ║"
    Write-Host "║  9. 添加监控网站                                                ║"
    Write-Host "║  A. 查看监控列表                                                ║"
    Write-Host "║  B. 批量检查网站状态                                            ║"
    Write-Host "╠══════════════════════════════════════════════════════════════╣"
    Write-Host "║  0. 返回                                                      ║"
    Write-Host "╚══════════════════════════════════════════════════════════════╝"
    Write-Host ""
}

function Initialize-Directories {
    if (-not (Test-Path $DataDir)) { New-Item -ItemType Directory -Path $DataDir -Force | Out-Null }
    if (-not (Test-Path $FeedsDir)) { New-Item -ItemType Directory -Path $FeedsDir -Force | Out-Null }
    if (-not (Test-Path $KeywordsDir)) { New-Item -ItemType Directory -Path $KeywordsDir -Force | Out-Null }
}

# ===== RSS 功能 =====

function Add-RssFeed {
    Write-Host ""
    Write-Host "[添加 RSS 源]" -ForegroundColor Cyan
    Write-Host ""
    
    $name = Read-Host "源名称 (如: 科技新闻)"
    $url = Read-Host "RSS URL"
    
    if ([string]::IsNullOrWhiteSpace($name) -or [string]::IsNullOrWhiteSpace($url)) {
        Write-Host "❌ 名称和 URL 不能为空" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    $feedFile = Join-Path $FeedsDir "$name.txt"
    $url | Out-File -FilePath $feedFile -Encoding UTF8
    
    Write-Host "✅ RSS 源已添加: $name" -ForegroundColor Green
    Read-Host "按 Enter 继续"
}

function Get-RssFeedList {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  RSS 源列表" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    $feeds = Get-ChildItem $FeedsDir -Filter "*.txt" -File
    if ($feeds.Count -eq 0) {
        Write-Host "  暂无 RSS 源" -ForegroundColor Gray
        return
    }
    
    $feeds | ForEach-Object -Begin { $i = 1 } -Process {
        $url = Get-Content $_.FullName -Raw
        Write-Host ("  {0,2}. {1,-20} -> {2}" -f $i, $_.BaseName, $url)
        $i++
    }
    Write-Host ""
    Write-Host ("  总计: {0} 个 RSS 源" -f $feeds.Count) -ForegroundColor Yellow
}

function Read-RssContent {
    Get-RssFeedList
    Write-Host ""
    
    $name = Read-Host "请输入要读取的源名称"
    if ([string]::IsNullOrWhiteSpace($name)) {
        Write-Host "❌ 名称不能为空" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    $feedFile = Join-Path $FeedsDir "$name.txt"
    if (-not (Test-Path $feedFile)) {
        Write-Host "❌ RSS 源不存在" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    $url = Get-Content $feedFile -Raw
    Write-Host ""
    Write-Host ("  正在获取: {0}" -f $url) -ForegroundColor Yellow
    
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing
        $content = $response.Content
        
        # 简单解析 (实际应该用 XML 解析器)
        if ($content -match "<item>(.*?)</item>") {
            Write-Host ""
            Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host "  最新内容" -ForegroundColor Cyan
            Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host $content.Substring(0, [Math]::Min(3000, $content.Length))
        } else {
            Write-Host "  无法解析 RSS 内容" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ 获取失败: $_" -ForegroundColor Red
    }
    
    Read-Host "按 Enter 继续"
}

function Remove-RssFeed {
    Get-RssFeedList
    Write-Host ""
    
    $name = Read-Host "请输入要删除的源名称"
    if ([string]::IsNullOrWhiteSpace($name)) {
        Write-Host "❌ 名称不能为空" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    $feedFile = Join-Path $FeedsDir "$name.txt"
    if (-not (Test-Path $feedFile)) {
        Write-Host "❌ RSS 源不存在" -ForegroundColor Red
    } else {
        Remove-Item $feedFile -Force
        Write-Host "✅ 已删除: $name" -ForegroundColor Green
    }
    
    Read-Host "按 Enter 继续"
}

# ===== 关键词功能 =====

function Add-Keyword {
    Write-Host ""
    Write-Host "[添加关键词]" -ForegroundColor Cyan
    Write-Host ""
    
    $keyword = Read-Host "关键词"
    $source = Read-Host "来源 (如: 知乎,微博,百度)"
    
    if ([string]::IsNullOrWhiteSpace($keyword)) {
        Write-Host "❌ 关键词不能为空" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    $keywordFile = Join-Path $KeywordsDir "$keyword.txt"
    @"
Keyword: $keyword
Source: $source
Added: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@ | Out-File -FilePath $keywordFile -Encoding UTF8
    
    Write-Host "✅ 关键词已添加: $keyword" -ForegroundColor Green
    Read-Host "按 Enter 继续"
}

function Get-KeywordList {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  关键词列表" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    $keywords = Get-ChildItem $KeywordsDir -Filter "*.txt" -File
    if ($keywords.Count -eq 0) {
        Write-Host "  暂无关键词" -ForegroundColor Gray
        return
    }
    
    $keywords | ForEach-Object -Begin { $i = 1 } -Process {
        $content = Get-Content $_.FullName -Raw
        if ($content -match "Source: (.+)") {
            $source = $matches[1]
        } else {
            $source = "未知"
        }
        Write-Host ("  {0,2}. {1,-20} (来源: {2})" -f $i, $_.BaseName, $source)
        $i++
    }
    Write-Host ""
    Write-Host ("  总计: {0} 个关键词" -f $keywords.Count) -ForegroundColor Yellow
}

function Search-Keyword {
    Get-KeywordList
    Write-Host ""
    
    $keyword = Read-Host "请输入要搜索的关键词"
    if ([string]::IsNullOrWhiteSpace($keyword)) {
        Write-Host "❌ 关键词不能为空" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    Write-Host ""
    Write-Host ("  正在搜索: {0}" -f $keyword) -ForegroundColor Yellow
    Write-Host "  (使用默认浏览器打开搜索)" -ForegroundColor Gray
    
    # 打开百度搜索
    $searchUrl = "https://www.baidu.com/s?wd=[uri]::EscapeDataString($keyword)"
    Start-Process "https://www.baidu.com/s?wd=$([uri]::EscapeDataString($keyword))"
    
    Write-Host "✅ 已打开浏览器" -ForegroundColor Green
    Read-Host "按 Enter 继续"
}

function Remove-Keyword {
    Get-KeywordList
    Write-Host ""
    
    $keyword = Read-Host "请输入要删除的关键词"
    if ([string]::IsNullOrWhiteSpace($keyword)) {
        Write-Host "❌ 关键词不能为空" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    $keywordFile = Join-Path $KeywordsDir "$keyword.txt"
    if (-not (Test-Path $keywordFile)) {
        Write-Host "❌ 关键词不存在" -ForegroundColor Red
    } else {
        Remove-Item $keywordFile -Force
        Write-Host "✅ 已删除: $keyword" -ForegroundColor Green
    }
    
    Read-Host "按 Enter 继续"
}

# ===== 网站监控功能 =====

$SitesDir = Join-Path $DataDir "sites"

function Initialize-SitesDir {
    if (-not (Test-Path $SitesDir)) { New-Item -ItemType Directory -Path $SitesSite -Force | Out-Null }
}

function Add-MonitorSite {
    Initialize-SitesDir
    Write-Host ""
    Write-Host "[添加监控网站]" -ForegroundColor Cyan
    Write-Host ""
    
    $name = Read-Host "网站名称"
    $url = Read-Host "网站 URL"
    
    if ([string]::IsNullOrWhiteSpace($name) -or [string]::IsNullOrWhiteSpace($url)) {
        Write-Host "❌ 名称和 URL 不能为空" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    $siteFile = Join-Path $SitesDir "$name.txt"
    @"
Name: $name
URL: $url
Added: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@ | Out-File -FilePath $siteFile -Encoding UTF8
    
    Write-Host "✅ 网站已添加: $name" -ForegroundColor Green
    Read-Host "按 Enter 继续"
}

function Get-SiteList {
    Initialize-SitesDir
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  监控网站列表" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    $sites = Get-ChildItem $SitesDir -Filter "*.txt" -File
    if ($sites.Count -eq 0) {
        Write-Host "  暂无监控网站" -ForegroundColor Gray
        return
    }
    
    $sites | ForEach-Object -Begin { $i = 1 } -Process {
        $content = Get-Content $_.FullName -Raw
        if ($content -match "URL: (.+)") {
            $url = $matches[1]
        } else {
            $url = "未知"
        }
        Write-Host ("  {0,2}. {1,-20} -> {2}" -f $i, $_.BaseName, $url)
        $i++
    }
    Write-Host ""
    Write-Host ("  总计: {0} 个网站" -f $sites.Count) -ForegroundColor Yellow
}

function Check-SiteStatus {
    Initialize-SitesDir
    Get-SiteList
    Write-Host ""
    
    $name = Read-Host "请输入要检查的网站名称 (留空检查所有)"
    Write-Host ""
    Write-Host "  正在检查网站状态..." -ForegroundColor Yellow
    Write-Host ""
    
    $sites = Get-ChildItem $SitesDir -Filter "*.txt" -File
    foreach ($site in $sites) {
        $content = Get-Content $site.FullName -Raw
        if ($content -match "URL: (.+)") {
            $url = $matches[1]
            $siteName = $site.BaseName
            
            try {
                $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
                $status = $response.StatusCode
                if ($status -eq 200) {
                    Write-Host ("  ✅ {0,-20} 正常 (HTTP {1})" -f $siteName, $status) -ForegroundColor Green
                } else {
                    Write-Host ("  ⚠️ {0,-20} 异常 (HTTP {1})" -f $siteName, $status) -ForegroundColor Yellow
                }
            } catch {
                Write-Host ("  ❌ {0,-20} 无法访问 ({1})" -f $siteName, $_.Exception.Message) -ForegroundColor Red
            }
        }
    }
    
    Read-Host "按 Enter 继续"
}

function Main {
    Initialize-Directories
    Initialize-SitesDir
    
    do {
        Show-InfoCollectorMenu
        $choice = (Read-Host "请选择操作").ToUpper()
        
        switch ($choice) {
            "1" { Add-RssFeed }
            "2" { Get-RssFeedList; Read-Host "按 Enter 继续" }
            "3" { Read-RssContent }
            "4" { Remove-RssFeed }
            "5" { Add-Keyword }
            "6" { Get-KeywordList; Read-Host "按 Enter 继续" }
            "7" { Search-Keyword }
            "8" { Remove-Keyword }
            "9" { Add-MonitorSite }
            "A" { Get-SiteList; Read-Host "按 Enter 继续" }
            "B" { Check-SiteStatus }
            "0" { return }
            default { 
                if (-not [string]::IsNullOrWhiteSpace($choice)) {
                    Write-Host "  无效选择" -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
            }
        }
    } while ($choice -ne "0")
}

Main
