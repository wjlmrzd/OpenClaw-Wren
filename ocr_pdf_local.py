import os
os.environ['PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK'] = 'True'

from paddleocr import PaddleOCR
import fitz
import time

# Initialize PaddleOCR (English + Chinese)
print("Initializing PaddleOCR...")
ocr = PaddleOCR(lang='ch')
print("PaddleOCR initialized!")

# PDF file path
pdf_dir = r'E:\工程规范'
pdf_files = [f for f in os.listdir(pdf_dir) if f.endswith('.pdf')]
pdf_path = os.path.join(pdf_dir, pdf_files[0])

print(f"\nProcessing: {pdf_files[0]}")

# Open PDF
doc = fitz.open(pdf_path)
total_pages = len(doc)
print(f"Total pages: {total_pages}")

# Process first 3 pages as preview
preview_pages = min(3, total_pages)
all_text = []

for page_num in range(preview_pages):
    print(f"\nProcessing page {page_num + 1}/{preview_pages}...")
    
    # Render page to image
    page = doc[page_num]
    mat = fitz.Matrix(2, 2)  # 2x zoom for better OCR
    pix = page.get_pixmap(matrix=mat)
    
    img_path = f'page_{page_num+1}.png'
    pix.save(img_path)
    print(f"  Rendered: {img_path} ({pix.width}x{pix.height})")
    
    # Run OCR
    start_time = time.time()
    result = ocr.ocr(img_path, cls=True)
    ocr_time = time.time() - start_time
    print(f"  OCR time: {ocr_time:.2f}s")
    
    # Extract text
    page_text = []
    if result and result[0]:
        for line in result[0]:
            text = line[1][0]
            confidence = line[1][1]
            page_text.append(text)
            print(f"    [{confidence:.2f}] {text[:50]}...")
    
    # Save combined text
    if page_text:
        all_text.append(f"\n=== Page {page_num + 1} ===\n" + "\n".join(page_text))
    
    # Clean up
    os.remove(img_path)

doc.close()

# Output results
if all_text:
    output = "\n".join(all_text)
    print("\n" + "="*50)
    print("OCR RESULTS PREVIEW")
    print("="*50)
    print(output[:3000])
    
    # Save to file
    output_path = r'D:\OpenClaw\.openclaw\workspace\pdf_ocr_result.txt'
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(output)
    print(f"\nFull results saved to: {output_path}")
else:
    print("\nNo text extracted!")
