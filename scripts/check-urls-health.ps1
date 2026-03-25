# 批量检测 URL 可用性
param(
    [int]$BatchSize = 20,
    [int]$TimeoutSec = 10,
    [int]$StartIndex = 0
)

$csvPath = "D:\OpenClaw\.openclaw\workspace\memory\edge-bookmarks.csv"
$resultsPath = "D:\OpenClaw\.openclaw\workspace\memory\bookmark-health-check.csv"

# 读取书签
$bookmarks = Import-Csv $csvPath -Encoding UTF8
$total = $bookmarks.Count
Write-Host "Total bookmarks: $total" -ForegroundColor Cyan

# 检测结果数组
$results = @()

# 检测函数
function Test-Url($url, $name, $path) {
    $result = [PSCustomObject]@{
        Name = $name
        Url = $url
        Path = $path
        Status = "Unknown"
        HttpCode = $null
        ResponseTime = $null
        Error = $null
        CheckedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    try {
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-WebRequest -Uri $url -Method HEAD -TimeoutSec $TimeoutSec -UseBasicParsing -ErrorAction Stop
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
            $result.Error = $_.Exception.Message.Substring(0, [Math]::Min(100, $_.Exception.Message.Length))
        }
        $result.ResponseTime = $timer.ElapsedMilliseconds
    }
    catch {
        $timer.Stop()
        $result.Status = "Error"
        $result.Error = $_.Exception.Message.Substring(0, [Math]::Min(100, $_.Exception.Message.Length))
    }
    
    return $result
}

# 批量检测
$endIndex = [Math]::Min($StartIndex + $BatchSize, $total)
$batch = $bookmarks[$StartIndex..($endIndex-1)]

Write-Host "Checking $StartIndex to $($endIndex-1)..." -ForegroundColor Yellow

foreach ($bookmark in $batch) {
    Write-Host "  Testing: $($bookmark.Name)" -NoNewline -ForegroundColor Gray
    $result = Test-Url $bookmark.Url $bookmark.Name $bookmark.Path
    $results += $result
    
    if ($result.Status -eq "OK") {
        Write-Host " [OK] ($($result.ResponseTime)ms)" -ForegroundColor Green
    } else {
        Write-Host " [$($result.Status)]" -ForegroundColor Red
    }
}

# 保存结果
$results | Export-Csv $resultsPath -NoTypeInformation -Encoding UTF8 -Append -Force

# 统计
$okCount = ($results | Where-Object { $_.Status -eq "OK" }).Count
Write-Host "Complete: $okCount/$($results.Count) OK" -ForegroundColor Cyan
