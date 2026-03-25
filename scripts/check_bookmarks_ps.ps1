# 批量检测 Edge 收藏夹中的网站可用性 - PowerShell 版本
$BookmarksPath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Bookmarks"
$OutputPath = "D:\OpenClaw\.openclaw\workspace\memory\bookmark-health-report.md"
$Proxy = "http://127.0.0.1:7897"

# 读取收藏夹
$json = Get-Content $BookmarksPath -Raw -Encoding UTF8 | ConvertFrom-Json

# 递归提取 URL
function Extract-Urls($node, $path = "") {
    $results = @()
    if ($node.type -eq "url") {
        $results += [PSCustomObject]@{
            Name = $node.name
            Url = $node.url
            Path = $path
            VisitCount = $node.visit_count
        }
    } elseif ($node.children) {
        $newPath = if ($path) { "$path > $($node.name)" } else { $node.name }
        foreach ($child in $node.children) {
            $results += Extract-Urls $child $newPath
        }
    }
    return $results
}

# 提取所有 URL
$allUrls = @()
foreach ($root in $json.roots.PSObject.Properties) {
    $allUrls += Extract-Urls $root.Value $root.Name
}

Write-Host "共找到 $($allUrls.Count) 个书签" -ForegroundColor Cyan
Write-Host "开始检测..." -ForegroundColor Yellow

# 检测函数
function Test-Url($url, $name) {
    $result = [PSCustomObject]@{
        Name = $name
        Url = $url
        Status = "Unknown"
        HttpCode = $null
        ResponseTime = $null
        Error = $null
    }
    
    if (-not ($url -match "^https?://")) {
        $result.Status = "Skipped"
        return $result
    }
    
    try {
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-WebRequest -Uri $url -Method GET -TimeoutSec 10 -Proxy $Proxy -UseBasicParsing -ErrorAction Stop
        $timer.Stop()
        
        $result.Status = "OK"
        $result.HttpCode = $response.StatusCode
        $result.ResponseTime = $timer.ElapsedMilliseconds
    }
    catch [System.Net.WebException] {
        $timer.Stop()
        if ($_.Exception.Response) {
            $result.Status = "HTTP Error"
            $result.HttpCode = [int]$_.Exception.Response.StatusCode
        } else {
            $result.Status = "Failed"
            $result.Error = $_.Exception.Message.Substring(0, [Math]::Min(50, $_.Exception.Message.Length))
        }
        $result.ResponseTime = $timer.ElapsedMilliseconds
    }
    catch {
        $timer.Stop()
        $result.Status = "Error"
        $result.Error = $_.Exception.Message.Substring(0, [Math]::Min(50, $_.Exception.Message.Length))
    }
    
    return $result
}

# 批量检测（限制数量避免太慢）
$testLimit = 100  # 先检测前 100 个
$results = @()
$count = 0

foreach ($bookmark in $allUrls | Select-Object -First $testLimit) {
    $count++
    Write-Host "[$count/$testLimit] Testing: $($bookmark.Name)" -NoNewline -ForegroundColor Gray
    $result = Test-Url $bookmark.Url $bookmark.Name
    $results += $result
    
    if ($result.Status -eq "OK") {
        Write-Host " [OK] ($($result.ResponseTime)ms)" -ForegroundColor Green
    } else {
        Write-Host " [$($result.Status)]" -ForegroundColor Red
    }
}

# 生成报告
$total = $results.Count
$ok = ($results | Where-Object { $_.Status -eq "OK" }).Count
$failed = ($results | Where-Object { $_.Status -in @("Failed", "HTTP Error", "Timeout", "Error") }).Count
$skipped = ($results | Where-Object { $_.Status -eq "Skipped" }).Count

$failedSites = $results | Where-Object { $_.Status -in @("Failed", "HTTP Error", "Timeout", "Error") }

$report = @"
# Edge 收藏夹健康检测报告

生成时间: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

> 使用代理: $Proxy
> 检测数量: $testLimit / $($allUrls.Count)

## 统计概览

| 指标 | 数量 | 占比 |
|------|------|------|
| 检测总数 | $total | 100% |
| 正常访问 | $ok | $([math]::Round($ok/$total*100, 1))% |
| 访问失败 | $failed | $([math]::Round($failed/$total*100, 1))% |
| 已跳过 | $skipped | $([math]::Round($skipped/$total*100, 1))% |

## 确认失效的网站

| 名称 | URL | 状态 | HTTP 码 |
|------|-----|------|---------|
"@

foreach ($site in $failedSites) {
    $httpCode = if ($site.HttpCode) { $site.HttpCode } else { "-" }
    $report += "| $($site.Name.Substring(0, [Math]::Min(28, $site.Name.Length))) | $($site.Url.Substring(0, [Math]::Min(45, $site.Url.Length)))... | $($site.Status) | $httpCode |`n"
}

$report += "`n## 详细结果`n`n"
$report += "| 名称 | URL | 状态 | HTTP 码 | 响应时间 |`n"
$report += "|------|-----|------|---------|----------|`n"

foreach ($site in $results) {
    $httpCode = if ($site.HttpCode) { $site.HttpCode } else { "-" }
    $responseTime = if ($site.ResponseTime) { "$($site.ResponseTime)ms" } else { "-" }
    $report += "| $($site.Name.Substring(0, [Math]::Min(22, $site.Name.Length))) | $($site.Url.Substring(0, [Math]::Min(40, $site.Url.Length)))... | $($site.Status) | $httpCode | $responseTime |`n"
}

# 保存报告
$report | Out-File $OutputPath -Encoding UTF8
Write-Host "`n报告已保存到: $OutputPath" -ForegroundColor Cyan
Write-Host "检测结果: $ok 个正常, $failed 个失败" -ForegroundColor Yellow
