import os
import base64
import json
import urllib.request
import sys

def ocr_image(image_path):
    """使用 PaddleOCR API 识别图片中的文字"""
    token = os.environ.get('PADDLEOCR_ACCESS_TOKEN')
    if not token:
        print("错误: PADDLEOCR_ACCESS_TOKEN 环境变量未设置")
        return None
    
    # 读取图片
    with open(image_path, 'rb') as f:
        img_data = f.read()
        base64_img = base64.b64encode(img_data).decode('utf-8')
    
    # 调用 PaddleOCR API
    url = 'https://ppocrapi.shuashua.com/ocrservice/v2/recognize'
    
    payload = {
        'image': base64_img,
        'sections': ['ocr', 'formula', 'table']
    }
    
    data = json.dumps(payload).encode('utf-8')
    
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {token}'
        },
        method='POST'
    )
    
    print(f'发送 OCR 请求: {image_path}')
    
    import ssl
    
    try:
        # 创建 SSL 上下文，忽略证书验证
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        
        with urllib.request.urlopen(req, timeout=120, context=ctx) as response:
            result = json.loads(response.read().decode('utf-8'))
            
            if result.get('code') == 0 and result.get('data') and len(result['data']) > 0:
                text = ''
                for item in result['data']:
                    text += item.get('text', '') + '\n'
                return text
            else:
                print(f'API 响应: {result}')
                return None
    except Exception as e:
        print(f'OCR 请求失败: {e}')
        return None

def main():
    # 获取 PDF 文件
    pdf_dir = r'E:\工程规范'
    os.chdir(pdf_dir)
    
    pdf_files = [f for f in os.listdir('.') if f.endswith('.pdf')]
    if not pdf_files:
        print('未找到 PDF 文件')
        return
    
    pdf_path = pdf_files[0]
    print(f'处理文件: {pdf_path}')
    
    # 渲染 PDF 页面
    import fitz
    
    doc = fitz.open(pdf_path)
    print(f'总页数: {len(doc)}')
    
    # 只处理前3页作为预览
    preview_pages = min(3, len(doc))
    
    all_text = []
    
    for page_num in range(preview_pages):
        print(f'\n处理第 {page_num + 1} 页...')
        
        # 渲染页面为图片
        page = doc[page_num]
        mat = fitz.Matrix(150/72, 150/72)  # 150 DPI
        pix = page.get_pixmap(matrix=mat)
        
        img_path = f'page_{page_num+1}.png'
        pix.save(img_path)
        print(f'已保存图片: {img_path}')
        
        # OCR
        text = ocr_image(img_path)
        if text:
            all_text.append(f'=== 第 {page_num + 1} 页 ===\n{text}')
            print(f'提取字符数: {len(text)}')
        else:
            print(f'第 {page_num + 1} 页 OCR 失败')
        
        # 删除临时图片
        os.remove(img_path)
    
    doc.close()
    
    # 输出结果
    if all_text:
        print('\n\n========== OCR 结果预览 ==========\n')
        for page_text in all_text:
            print(page_text)
            print()
    else:
        print('\n未能提取任何文字')

if __name__ == '__main__':
    main()
