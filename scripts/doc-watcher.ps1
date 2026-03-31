# 工程文档自动解析器
# 功能:定期扫描文件夹,自动解析新文档并创建原子笔记

param(
    [string]$WatchFolder = "E:\EngineeringDocs",
    [string]$VaultPath = "E:\software\Obsidian\vault",
    [switch]$DryRun
)

$ErrorActionPreference = "Continue"
$LogFile = "D:\OpenClaw\.openclaw\workspace\memory\doc-watcher.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [$Level] $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    Write-Host "$timestamp [$Level] $Message"
}

function Get-FileHashFast {
    param([string]$Path)
    try {
        $hash = Get-FileHash -Path $Path -Algorithm MD5 -ErrorAction Stop
        return $hash.Hash
    } catch {
        return $null
    }
}

Write-Log "=== 工程文档自动解析器启动 ==="
Write-Log "监控文件夹: $WatchFolder"

# 检查监控文件夹
if (-not (Test-Path $WatchFolder)) {
    Write-Log "监控文件夹不存在,创建: $WatchFolder"
    New-Item -ItemType Directory -Path $WatchFolder -Force | Out-Null
}

# 状态文件
$StateFile = "D:\OpenClaw\.openclaw\workspace\memory\doc-watcher-state.json"
$state = @{
    lastRun = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    processed = @()
    errors = @()
}

if (Test-Path $StateFile) {
    try {
        $state = Get-Content $StateFile -Raw | ConvertFrom-Json
    } catch {
        Write-Log "状态文件读取失败,使用空白状态"
    }
}

# 扫描支持的文档类型
$supportedExtensions = @(".pdf", ".png", ".jpg", ".jpeg", ".tiff", ".tif", ".bmp", ".docx", ".xlsx")
$newFiles = @()

foreach ($ext in $supportedExtensions) {
    $files = Get-ChildItem -Path $WatchFolder -Filter "*$ext" -File -ErrorAction SilentlyContinue | Where-Object {
        $processed = $state.processed -contains $_.FullName
        -not $processed
    }
    $newFiles += $files
}

Write-Log "发现 $($newFiles.Count) 个新文件待处理"

if ($newFiles.Count -eq 0) {
    Write-Log "无新文件,退出"
    $state.lastRun = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    $state | ConvertTo-Json -Depth 10 | Out-File -FilePath $StateFile -Encoding UTF8
    return
}

# 处理每个新文件
$processedCount = 0
$skippedCount = 0

foreach ($file in $newFiles) {
    Write-Log "处理文件: $($file.Name)"
    
    if ($DryRun) {
        Write-Log "  [DryRun] 会处理此文件"
        continue
    }
    
    try {
        # 识别文档类型
        $docType = "Unknown"
        $docId = ""
        
        switch ($file.Extension.ToLower()) {
            ".pdf" { $docType = "PDF" }
            {".png", ".jpg", ".jpeg", ".tiff", ".tif", ".bmp"} { $docType = "Image" }
            ".docx" { $docType = "Word" }
            ".xlsx" { $docType = "Excel" }
        }
        
        # 尝试识别文档编号
        $fileName = $file.BaseName
        if ($fileName -match "^([A-Z]{2}[/]?[A-Z0-9]+)[-_](\d+[\d\.]*)") {
            $docId = $Matches[0] -replace "[_\-]", "_"
        } elseif ($fileName -match "([A-Z]{2,4})[-_]?(\d+)") {
            $docId = "$($Matches[1])_$($Matches[2])"
        } else {
            $docId = $fileName -replace "[^\w]", "_"
        }
        
        # 目标路径
        $targetDir = Join-Path $VaultPath "knowledge\工程知识\00-Inbox"
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        
        # 创建解析任务记录
        $taskNote = @"
---
title: "待解析: $($file.Name)"
source: "$($file.Name)"
type: $docType
docId: "$docId"
status: pending_review
created: $(Get-Date -Format "yyyy-MM-dd")
watchFolder: "$($file.FullName)"
tags: [待解析, 工程知识]
---

# 待解析: $($file.Name)

## 文档信息
- **文件名**: $($file.Name)
- **类型**: $docType
- **大小**: $([math]::Round($file.Length / 1KB, 1)) KB
- **修改时间**: $($file.LastWriteTime.ToString("yyyy-MM-dd HH:mm"))
- **文档ID**: $docId
- **原始路径**: $($file.FullName)

## 解析状态
- [ ] 内容提取
- [ ] 条款分割
- [ ] 关联建立
- [ ] 来源标注

## 下一步
使用以下命令触发解析:
解析此文件并保存到工程知识篇章
[附件: $($file.FullName)]
"@
        
        $outputFile = Join-Path $targetDir "$($docId)_pending.md"
        $taskNote | Out-File -FilePath $outputFile -Encoding UTF8
        
        Write-Log "  创建解析任务: $docId"
        $state.processed += $file.FullName
        $processedCount++
        
    } catch {
        Write-Log "  处理失败: $($_.Exception.Message)" "ERROR"
        $state.errors += @{
            file = $file.FullName
            error = $_.Exception.Message
            time = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        }
        $skippedCount++
    }
}

# 保存状态
$state.lastRun = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
$state | ConvertTo-Json -Depth 10 | Out-File -FilePath $StateFile -Encoding UTF8

Write-Log "=== 处理完成 ==="
Write-Log "已处理: $processedCount, 跳过: $skippedCount, 待处理: $($newFiles.Count)"

if ($processedCount -gt 0) {
    Write-Log "新解析任务已创建到: knowledge\工程知识\00-Inbox"
}
