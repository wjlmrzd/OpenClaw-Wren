# 读取 Edge 收藏夹并提取所有 URL
$bookmarksPath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Bookmarks"
$json = Get-Content $bookmarksPath -Raw -Encoding UTF8 | ConvertFrom-Json

# 递归提取所有 URL
function Extract-Urls($node, $path = "") {
    $results = @()
    
    if ($node.type -eq "url") {
        $results += [PSCustomObject]@{
            Name = $node.name
            Url = $node.url
            Path = $path
            VisitCount = $node.visit_count
            DateAdded = if ($node.date_added) { [DateTime]::FromFileTimeUtc($node.date_added) } else { $null }
        }
    }
    elseif ($node.type -eq "folder" -or $node.children) {
        $newPath = if ($path) { "$path > $($node.name)" } else { $node.name }
        foreach ($child in $node.children) {
            $results += Extract-Urls $child $newPath
        }
    }
    
    return $results
}

# 从所有根目录提取
$allUrls = @()
foreach ($root in $json.roots.PSObject.Properties) {
    $allUrls += Extract-Urls $root.Value $root.Name
}

# 输出统计
Write-Host "Total bookmarks found: $($allUrls.Count)" -ForegroundColor Green

# 保存到文件
$outputPath = "D:\OpenClaw\.openclaw\workspace\memory\edge-bookmarks.csv"
$allUrls | Export-Csv $outputPath -NoTypeInformation -Encoding UTF8
Write-Host "Saved to: $outputPath" -ForegroundColor Cyan

# 显示前 20 个
$allUrls | Select-Object -First 20 | Format-Table Name, Url -Wrap
