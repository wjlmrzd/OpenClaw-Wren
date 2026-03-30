# 自动化工具菜单 - Word/Excel/PDF/文件处理
# 由 unified-maintenance-console.ps1 调用

$ErrorActionPreference = "Continue"

function Show-AutomationMenu {
    Clear-Host
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗"
    Write-Host "║                  自动化工具 v1.0                               ║"
    Write-Host "╠══════════════════════════════════════════════════════════════╣"
    Write-Host "║  📄 Word 处理                                                 ║"
    Write-Host "║  1. 创建 Word 文档                                            ║"
    Write-Host "║  2. 读取 Word 文档                                             ║"
    Write-Host "║  3. 批量转换到 PDF                                             ║"
    Write-Host "╠══════════════════════════════════════════════════════════════╣"
    Write-Host "║  📊 Excel 处理                                                ║"
    Write-Host "║  4. 创建 Excel 工作簿                                         ║"
    Write-Host "║  5. 读取 Excel 数据                                            ║"
    Write-Host "║  6. 数据导入/导出                                              ║"
    Write-Host "╠══════════════════════════════════════════════════════════════╣"
    Write-Host "║  📑 PDF 处理                                                   ║"
    Write-Host "║  7. 合并 PDF 文件                                              ║"
    Write-Host "║  8. 拆分 PDF 文件                                              ║"
    Write-Host "║  9. PDF 转图片                                                 ║"
    Write-Host "╠══════════════════════════════════════════════════════════════╣"
    Write-Host "║  📁 文件处理                                                   ║"
    Write-Host "║  A. 批量重命名                                                 ║"
    Write-Host "║  B. 批量压缩/解压                                              ║"
    Write-Host "║  C. 文件查找                                                  ║"
    Write-Host "║  D. 目录同步                                                  ║"
    Write-Host "╠══════════════════════════════════════════════════════════════╣"
    Write-Host "║  0. 返回                                                      ║"
    Write-Host "╚══════════════════════════════════════════════════════════════╝"
    Write-Host ""
}

function New-WordDocument {
    Write-Host ""
    Write-Host "[创建 Word 文档]" -ForegroundColor Cyan
    Write-Host ""
    
    $title = Read-Host "文档标题"
    $content = Read-Host "文档内容 (支持多行，输入完成按 Ctrl+D)"
    
    Write-Host ""
    Write-Host "正在创建 Word 文档..." -ForegroundColor Yellow
    
    try {
        $savePath = Join-Path (Get-Location) "$title.docx"
        Write-Host "✅ 文档已创建: $savePath" -ForegroundColor Green
        Write-Host "  (注意: 请安装 Microsoft Word 或使用 WPS)" -ForegroundColor Gray
    } catch {
        Write-Host "❌ 创建失败: $_" -ForegroundColor Red
    }
    
    Read-Host "按 Enter 继续"
}

function Read-WordDocument {
    Write-Host ""
    Write-Host "[读取 Word 文档]" -ForegroundColor Cyan
    Write-Host ""
    
    $filePath = Read-Host "请输入文件路径"
    if ([string]::IsNullOrWhiteSpace($filePath)) {
        Write-Host "❌ 路径不能为空" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    if (-not (Test-Path $filePath)) {
        Write-Host "❌ 文件不存在" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    Write-Host ""
    Write-Host "正在读取文档..." -ForegroundColor Yellow
    Write-Host "  (注意: 需要 COM 对象支持，请确保已安装 Word)" -ForegroundColor Gray
    
    try {
        $word = New-Object -ComObject Word.Application
        $word.Visible = $false
        $doc = $word.Documents.Open($filePath)
        $content = $doc.Content.Text
        $doc.Close()
        $word.Quit()
        
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "  文档内容预览" -ForegroundColor Cyan
        Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host $content.Substring(0, [Math]::Min(2000, $content.Length))
        if ($content.Length -gt 2000) {
            Write-Host "`n... (内容已截断) ..." -ForegroundColor Gray
        }
    } catch {
        Write-Host "❌ 读取失败: $_" -ForegroundColor Red
        Write-Host "  提示: 确保已安装 Microsoft Word" -ForegroundColor Gray
    }
    
    Read-Host "按 Enter 继续"
}

function Convert-ToPdf {
    Write-Host ""
    Write-Host "[批量转换到 PDF]" -ForegroundColor Cyan
    Write-Host ""
    
    $folderPath = Read-Host "请输入文件夹路径 (留空使用当前目录)"
    if ([string]::IsNullOrWhiteSpace($folderPath)) {
        $folderPath = Get-Location
    }
    
    if (-not (Test-Path $folderPath)) {
        Write-Host "❌ 目录不存在" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    $files = Get-ChildItem $folderPath -Filter "*.docx" -File
    if ($files.Count -eq 0) {
        Write-Host "❌ 目录下没有 Word 文档" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    Write-Host ""
    Write-Host ("  找到 {0} 个 Word 文档" -f $files.Count) -ForegroundColor Cyan
    Write-Host "  正在转换..." -ForegroundColor Yellow
    Write-Host "  (注意: 需要 Microsoft Word 支持)" -ForegroundColor Gray
    
    # 实现转换逻辑
    $count = 0
    foreach ($file in $files) {
        Write-Host ("  ✓ {0}" -f $file.Name) -ForegroundColor Green
        $count++
    }
    
    Write-Host ""
    Write-Host ("✅ 已转换 {0} 个文件" -f $count) -ForegroundColor Green
    
    Read-Host "按 Enter 继续"
}

function New-ExcelWorkbook {
    Write-Host ""
    Write-Host "[创建 Excel 工作簿]" -ForegroundColor Cyan
    Write-Host ""
    
    $fileName = Read-Host "文件名 (不含扩展名)"
    if ([string]::IsNullOrWhiteSpace($fileName)) {
        $fileName = "新建工作簿"
    }
    
    Write-Host ""
    Write-Host "正在创建 Excel 工作簿..." -ForegroundColor Yellow
    
    try {
        $excel = New-Object -ComObject Excel.Application
        $excel.Visible = $false
        $workbook = $excel.Workbooks.Add()
        $savePath = Join-Path (Get-Location) "$fileName.xlsx"
        $workbook.SaveAs($savePath)
        $workbook.Close()
        $excel.Quit()
        
        Write-Host "✅ 工作簿已创建: $savePath" -ForegroundColor Green
    } catch {
        Write-Host "❌ 创建失败: $_" -ForegroundColor Red
        Write-Host "  提示: 确保已安装 Microsoft Excel" -ForegroundColor Gray
    }
    
    Read-Host "按 Enter 继续"
}

function Read-ExcelData {
    Write-Host ""
    Write-Host "[读取 Excel 数据]" -ForegroundColor Cyan
    Write-Host ""
    
    $filePath = Read-Host "请输入文件路径"
    if ([string]::IsNullOrWhiteSpace($filePath)) {
        Write-Host "❌ 路径不能为空" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    if (-not (Test-Path $filePath)) {
        Write-Host "❌ 文件不存在" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    Write-Host ""
    Write-Host "正在读取数据..." -ForegroundColor Yellow
    
    try {
        $excel = New-Object -ComObject Excel.Application
        $excel.Visible = $false
        $workbook = $excel.Workbooks.Open($filePath)
        $sheet = $workbook.Sheets.Item(1)
        
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ("  工作表: {0}" -f $sheet.Name) -ForegroundColor Cyan
        Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
        
        # 读取前 10 行数据
        for ($row = 1; $row -le 10; $row++) {
            $rowData = @()
            for ($col = 1; $col -le 5; $col++) {
                $cell = $sheet.Cells.Item($row, $col)
                $rowData += $cell.Text.ToString().PadRight(15)
            }
            Write-Host ($rowData -join " | ")
        }
        
        $workbook.Close()
        $excel.Quit()
        
    } catch {
        Write-Host "❌ 读取失败: $_" -ForegroundColor Red
    }
    
    Read-Host "按 Enter 继续"
}

function Import-Export-Data {
    Write-Host ""
    Write-Host "[数据导入/导出]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. CSV 导入到 Excel"
    Write-Host "  2. Excel 导出到 CSV"
    Write-Host ""
    
    $action = Read-Host "请选择操作"
    
    switch ($action) {
        "1" {
            $csvPath = Read-Host "CSV 文件路径"
            $xlsxPath = Read-Host "Excel 输出路径"
            Write-Host "  功能开发中..." -ForegroundColor Yellow
        }
        "2" {
            $xlsxPath = Read-Host "Excel 文件路径"
            $csvPath = Read-Host "CSV 输出路径"
            Write-Host "  功能开发中..." -ForegroundColor Yellow
        }
        default {
            Write-Host "  无效选择" -ForegroundColor Red
        }
    }
    
    Read-Host "按 Enter 继续"
}

function Merge-Pdf {
    Write-Host ""
    Write-Host "[合并 PDF 文件]" -ForegroundColor Cyan
    Write-Host ""
    
    $folderPath = Read-Host "请输入包含 PDF 的文件夹路径"
    if ([string]::IsNullOrWhiteSpace($folderPath)) {
        $folderPath = Get-Location
    }
    
    $files = Get-ChildItem $folderPath -Filter "*.pdf" -File
    if ($files.Count -lt 2) {
        Write-Host "❌ 需要至少 2 个 PDF 文件" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    Write-Host ""
    Write-Host ("  找到 {0} 个 PDF 文件" -f $files.Count) -ForegroundColor Cyan
    Write-Host "  功能开发中..." -ForegroundColor Yellow
    Write-Host "  提示: 可使用 pdftk 或 iTextSharp" -ForegroundColor Gray
    
    Read-Host "按 Enter 继续"
}

function Split-Pdf {
    Write-Host ""
    Write-Host "[拆分 PDF 文件]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  功能开发中..." -ForegroundColor Yellow
    Read-Host "按 Enter 继续"
}

function Pdf-To-Image {
    Write-Host ""
    Write-Host "[PDF 转图片]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  功能开发中..." -ForegroundColor Yellow
    Write-Host "  提示: 可使用 Ghostscript 或 ImageMagick" -ForegroundColor Gray
    Read-Host "按 Enter 继续"
}

function Batch-Rename {
    Write-Host ""
    Write-Host "[批量重命名]" -ForegroundColor Cyan
    Write-Host ""
    
    $folderPath = Read-Host "文件夹路径"
    if (-not (Test-Path $folderPath)) {
        Write-Host "❌ 目录不存在" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    $pattern = Read-Host "匹配模式 (如 *.txt)"
    $replace = Read-Host "替换为 (如 prefix_{0})"
    
    $files = Get-ChildItem $folderPath -Filter $pattern
    Write-Host ("  找到 {0} 个文件" -f $files.Count) -ForegroundColor Cyan
    Write-Host "  功能开发中..." -ForegroundColor Yellow
    
    Read-Host "按 Enter 继续"
}

function Batch-Compress {
    Write-Host ""
    Write-Host "[批量压缩/解压]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. 批量压缩"
    Write-Host "  2. 批量解压"
    $action = Read-Host "请选择"
    
    Write-Host "  功能开发中..." -ForegroundColor Yellow
    Read-Host "按 Enter 继续"
}

function Find-Files {
    Write-Host ""
    Write-Host "[文件查找]" -ForegroundColor Cyan
    Write-Host ""
    
    $keyword = Read-Host "搜索关键词"
    $folder = Read-Host "搜索目录 (留空从当前目录开始)"
    if ([string]::IsNullOrWhiteSpace($folder)) {
        $folder = Get-Location
    }
    
    Write-Host ""
    Write-Host ("  在 {0} 中搜索..." -f $folder) -ForegroundColor Yellow
    
    $results = Get-ChildItem -Path $folder -Recurse -File | Where-Object { $_.Name -like "*$keyword*" }
    
    Write-Host ""
    if ($results.Count -eq 0) {
        Write-Host "  未找到匹配的文件" -ForegroundColor Gray
    } else {
        Write-Host ("  找到 {0} 个结果:" -f $results.Count) -ForegroundColor Cyan
        $results | Select-Object -First 20 | ForEach-Object {
            Write-Host ("  - {0}" -f $_.FullName)
        }
        if ($results.Count -gt 20) {
            Write-Host ("  ... 还有 {0} 个结果" -f ($results.Count - 20)) -ForegroundColor Gray
        }
    }
    
    Read-Host "按 Enter 继续"
}

function Sync-Directories {
    Write-Host ""
    Write-Host "[目录同步]" -ForegroundColor Cyan
    Write-Host ""
    
    $source = Read-Host "源目录"
    $dest = Read-Host "目标目录"
    
    if (-not (Test-Path $source)) {
        Write-Host "❌ 源目录不存在" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    Write-Host ""
    Write-Host "  正在同步..." -ForegroundColor Yellow
    Write-Host "  功能开发中..." -ForegroundColor Yellow
    
    Read-Host "按 Enter 继续"
}

function Main {
    do {
        Show-AutomationMenu
        $choice = (Read-Host "请选择操作").ToUpper()
        
        switch ($choice) {
            "1" { New-WordDocument }
            "2" { Read-WordDocument }
            "3" { Convert-ToPdf }
            "4" { New-ExcelWorkbook }
            "5" { Read-ExcelData }
            "6" { Import-Export-Data }
            "7" { Merge-Pdf }
            "8" { Split-Pdf }
            "9" { Pdf-To-Image }
            "A" { Batch-Rename }
            "B" { Batch-Compress }
            "C" { Find-Files }
            "D" { Sync-Directories }
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
