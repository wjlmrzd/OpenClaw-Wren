import fitz
import os

# PDF 文件路径
pdf_dir = r'E:\工程规范'
pdf_files = [f for f in os.listdir(pdf_dir) if f.endswith('.pdf')]
pdf_path = os.path.join(pdf_dir, pdf_files[0])

doc = fitz.open(pdf_path)

print('PDF 文档信息:')
print(f'文件名: {pdf_files[0]}')
print(f'大小: {os.path.getsize(pdf_path)/1024:.2f} KB')
print(f'页数: {len(doc)}')

# 检查是否有文本层
has_text = False
text_count = 0
for page in doc:
    text = page.get_text()
    if text.strip():
        has_text = True
        text_count += len(text.strip())

print(f'文本层: {"有" if has_text else "无 (扫描版)"}')
if has_text:
    print(f'文本字符数: {text_count}')

# 获取 PDF 元数据
meta = doc.metadata
if meta:
    print('\n元数据:')
    for key, value in meta.items():
        if value:
            print(f'  {key}: {value}')

# 如果是扫描版，说明需要 OCR
if not has_text:
    print('\n⚠️ 这是扫描版 PDF，需要 OCR 才能提取文字内容')
    print('当前 OCR 状态:')
    print('  - PaddleOCR API: SSL 连接问题')
    print('  - 本地 PaddleOCR: 正在安装中')
    print('  - Tesseract OCR: 未安装')

doc.close()