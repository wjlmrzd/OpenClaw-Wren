#!/usr/bin/env python3
"""OCR PDF and save extracted text to file."""

import pdfplumber
from paddleocr import PaddleOCR
import numpy as np
import json
import os
import sys

# Configuration
PDF_PATH = r'D:\OpenClaw\.openclaw\workspace\temp_pdf.pdf'
OUTPUT_PATH = r'D:\OpenClaw\.openclaw\workspace\temp_pdf_ocr.json'
LOG_PATH = r'D:\OpenClaw\.openclaw\workspace\temp_pdf_ocr.log'

def log(msg):
    """Log message to file and stdout."""
    print(msg)
    with open(LOG_PATH, 'a', encoding='utf-8') as f:
        f.write(msg + '\n')

def main():
    # Initialize
    log("Initializing PaddleOCR...")
    # Use simple OCR mode
    ocr = PaddleOCR(lang='ch', use_angle_cls=False)
    
    log(f"Opening PDF: {PDF_PATH}")
    with pdfplumber.open(PDF_PATH) as pdf:
        total_pages = len(pdf.pages)
        log(f"Total pages: {total_pages}")
        
        all_text = []
        
        # OCR all pages
        for page_num in range(total_pages):
            if page_num % 5 == 0:
                log(f"Processing page {page_num + 1}/{total_pages}...")
            
            page = pdf.pages[page_num]
            
            # Convert page to image
            img = page.to_image()
            img_array = np.array(img.original)
            
            # OCR
            result = ocr.ocr(img_array)
            
            page_text = []
            if result and result[0]:
                for line in result[0]:
                    text = line[1][0]
                    page_text.append(text)
            
            page_content = '\n'.join(page_text)
            all_text.append({
                'page': page_num + 1,
                'text': page_content
            })
            
            # Save progress every 10 pages
            if (page_num + 1) % 10 == 0:
                with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
                    json.dump({'pages': all_text, 'total_pages': total_pages, 'progress': page_num + 1}, f, ensure_ascii=False, indent=2)
        
        # Final save
        with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
            json.dump({'pages': all_text, 'total_pages': total_pages, 'progress': total_pages, 'complete': True}, f, ensure_ascii=False, indent=2)
        
        log(f"Complete! Extracted text from {total_pages} pages.")
        log(f"Output saved to: {OUTPUT_PATH}")

if __name__ == '__main__':
    # Clear log
    if os.path.exists(LOG_PATH):
        os.remove(LOG_PATH)
    main()
