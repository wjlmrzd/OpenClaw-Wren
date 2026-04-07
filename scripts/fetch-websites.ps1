# fetch-websites.ps1 - 网站抓取脚本
param(
    [string]$Url
)

try {
    $response = Invoke-WebRequest -Uri $Url -TimeoutSec 30 -UseBasicParsing -Headers @{
        'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }
    
    # 正确处理编码
    $content = [System.Text.Encoding]::UTF8.GetString($response.RawContentStream.ToArray())
    
    # 提取标题和链接
    $titles = @()
    $titleMatches = [regex]::Matches($content, '<a[^>]*href="([^"]+)"[^>]*title="([^"]+)"')
    foreach ($match in $titleMatches) {
        if ($match.Groups[2].Value.Length -gt 10) {
            $titles += @{
                link = $match.Groups[1].Value
                title = $match.Groups[2].Value
            }
        }
    }
    
    # 如果没找到 title 属性，尝试从 h 标签提取
    if ($titles.Count -eq 0) {
        $hMatches = [regex]::Matches($content, '<h[2-4][^>]*>([^<]+)</h[2-4]>')
        foreach ($match in $hMatches) {
            $title = $match.Groups[1].Value -replace '<[^>]+>', '' -replace '\s+', ' '
            if ($title.Length -gt 10) {
                $titles += @{
                    title = $title.Trim()
                }
            }
        }
    }
    
    @{
        url = $Url
        status = 'ok'
        titles = $titles | Select-Object -First 10
        contentLength = $content.Length
    } | ConvertTo-Json -Depth 3 -Compress
} catch {
    @{
        url = $Url
        status = 'error'
        error = $_.Exception.Message
    } | ConvertTo-Json -Compress
}