# OCR 扫描文档处理器
# 功能:使用 PaddleOCR API 识别扫描文档中的文字

param(
    [Parameter(Mandatory=$true)]
    [string]$ImagePath,
    
    [string]$OutputPath = "",
    
    [string]$PaddleOCRUrl = "https://ppocrapi.shuashua.com/ocrservice/v2/recognize",
    
    [switch]$SaveToClipboard
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "$timestamp [$Level] $Message"
}

# 检查文件
if (-not (Test-Path $ImagePath)) {
    Write-Log "文件不存在: $ImagePath" "ERROR"
    exit 1
}

$file = Get-Item $ImagePath
Write-Log "开始 OCR 识别: $($file.Name)"

# 获取 PaddleOCR 令牌
$token = $env:PADDLEOCR_ACCESS_TOKEN
if ([string]::IsNullOrEmpty($token)) {
    Write-Log "PaddleOCR 令牌未配置,请设置 PADDLEOCR_ACCESS_TOKEN 环境变量" "ERROR"
    Write-Log "获取方式: https://shuashua.com/paddleocr"
    exit 1
}

try {
    # 读取图片并转为 Base64
    $imageBytes = [System.IO.File]::ReadAllBytes($ImagePath)
    $base64Image = [Convert]::ToBase64String($imageBytes)
    
    # 构建请求
    $headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer $token"
    }
    
    $body = @{
        image = $base64Image
        sections = @("ocr", "formula", "table")
    } | ConvertTo-Json -Compress
    
    Write-Log "发送 OCR 请求..."
    
    # 调用 API
    $response = Invoke-RestMethod -Uri $PaddleOCRUrl -Method Post -Headers $headers -Body $body -TimeoutSec 60
    
    # 提取文字
    $extractedText = ""
    if ($response.data -and $response.data.Length -gt 0) {
        foreach ($item in $response.data) {
            $extractedText += $item.text + "`n"
        }
    }
    
    if ([string]::IsNullOrEmpty($extractedText)) {
        Write-Log "未识别到文字" "WARNING"
        $extractedText = "[OCR 未能识别文字]"
    }
    
    Write-Log "识别完成,提取 $($extractedText.Length) 字符"
    
    # 输出结果
    if ($SaveToClipboard) {
        $extractedText | Set-Clipboard
        Write-Log "已复制到剪贴板"
    }
    
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        # 生成带标注的笔记
        $noteContent = @"
---
title: "OCR 识别: $($file.Name)"
source: "$($file.Name)"
type: ocr_scanned
status: raw_text
created: $(Get-Date -Format "yyyy-MM-dd")
tags: [OCR, 扫描文档]
---

# OCR 识别结果: $($file.Name)

## 文档信息
- **文件名**: $($file.Name)
- **大小**: $([math]::Round($file.Length / 1KB, 1)) KB
- **识别时间**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **OCR 引擎**: PaddleOCR

## 识别结果

$extractedText

---

## 下一步
1. 检查识别结果是否准确
2. 如需修正,编辑上方内容
3. 使用以下格式保存到工程知识篇章
"@
        
        $noteContent | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Log "笔记已保存: $OutputPath"
    }
    
    # 输出到控制台
    Write-Output $extractedText
    
} catch {
    Write-Log "OCR 识别失败: $($_.Exception.Message)" "ERROR"
    exit 1
}
