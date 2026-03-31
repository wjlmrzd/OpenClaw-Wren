# PDF OCR 完整处理脚本
# 功能: 使用本地PaddleOCR对扫描版PDF进行文字识别

param(
    [Parameter(Mandatory=$true)]
    [string]$PdfPath,
    
    [string]$OutputPath = "",
    
    [string]$TempDir = "E:\工程规范\OCR_temp"
)

$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "$timestamp [$Level] $Message"
}

Write-Log "开始处理 PDF: $PdfPath"

# 检查Python和PaddleOCR
Write-Log "检查环境..."
$pythonVersion = python --version 2>&1
Write-Log "Python版本: $pythonVersion"

# 清理并创建临时目录
if (Test-Path $TempDir) {
    Remove-Item "$TempDir\*" -Force -ErrorAction SilentlyContinue
} else {
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
}

# 转换PDF为图片
Write-Log "阶段1: 提取PDF页面为图片..."
python -c @"
import fitz
import sys
import os
sys.stdout.reconfigure(encoding='utf-8')

pdf_path = r'$PdfPath'
output_dir = r'$TempDir'
os.makedirs(output_dir, exist_ok=True)

doc = fitz.open(pdf_path)
print(f'PDF总页数: {len(doc)}')

for page_num in range(len(doc)):
    page = doc[page_num]
    mat = fitz.Matrix(2, 2)
    pix = page.get_pixmap(matrix=mat)
    img_path = os.path.join(output_dir, f'page_{page_num+1:03d}.png')
    pix.save(img_path)
    if (page_num + 1) % 10 == 0:
        print(f'已提取: {page_num + 1}/{len(doc)} 页')

doc.close()
print('PDF转图片完成')
"@

if ($LASTEXITCODE -ne 0) {
    Write-Log "PDF转图片失败" "ERROR"
    exit 1
}

# OCR识别
Write-Log "阶段2: OCR文字识别..."
$images = Get-ChildItem "$TempDir\*.png" | Sort-Object Name
$totalPages = $images.Count
Write-Log "待处理: $totalPages 张图片"

# 创建Python OCR脚本
$ocrScript = @"
import sys
sys.stdout.reconfigure(encoding='utf-8')
from paddleocr import PaddleOCR
import time

print('初始化PaddleOCR (首次较慢)...')
ocr = PaddleOCR(lang='ch')

import os
import glob

images = sorted(glob.glob(r'$TempDir\*.png'))
all_text = []

for idx, img_path in enumerate(images):
    page_num = idx + 1
    result = ocr.ocr(img_path)
    
    page_text = f'\\n--- 第{page_num}页 ---\\n'
    if result and result[0]:
        for line in result[0]:
            page_text += line[1][0] + '\\n'
    else:
        page_text += '[此页未识别到文字]\\n'
    
    all_text.append(page_text)
    
    if page_num % 5 == 0 or page_num == len(images):
        print(f'进度: {page_num}/{len(images)}')

# 保存结果
output_file = r'$OutputPath'
with open(output_file, 'w', encoding='utf-8') as f:
    f.write('# 公路路面基层施工技术细则 (JTGT F20-2015) OCR识别结果\\n')
    f.write('# 文档共 ${totalPages} 页\\n')
    f.write('# 识别时间: ' + time.strftime('%Y-%m-%d %H:%M:%S') + '\\n\\n')
    f.writelines(all_text)

print(f'OCR完成，结果已保存到: {output_file}')
"@

$ocrScriptPath = "$TempDir\ocr_process.py"
$ocrScript | Out-File -FilePath $ocrScriptPath -Encoding UTF8

# 执行OCR
Write-Log "开始OCR识别 (可能需要几分钟到几十分钟)..."
python $ocrScriptPath

if ($LASTEXITCODE -ne 0) {
    Write-Log "OCR识别失败" "ERROR"
    exit 1
}

Write-Log "处理完成!"
Write-Log "输出文件: $OutputPath"
