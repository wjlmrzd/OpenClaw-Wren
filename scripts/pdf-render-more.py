# -*- coding: utf-8 -*-
import pypdfium2 as pdfium
from PIL import Image
import os

path = r"E:\工程规范\JTGT F20-2015 公路路面基层施工技术细则.pdf"
out_dir = r"D:\OpenClaw\.openclaw\workspace\scripts\pdf-preview"

pdf = pdfium.PdfDocument(path)
n = len(pdf)

# 渲染原材料要求和附录级配表格页
page_indices = [12, 13, 14, 15, 16, 17, 18, 19, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85]

for idx in page_indices:
    if idx >= n:
        continue
    out = os.path.join(out_dir, f"page_{idx+1:02d}.png")
    if not os.path.exists(out):
        page = pdf[idx]
        pil_page = page.render(scale=1.5, rotation=0)
        img = pil_page.to_pil()
        img.save(out)
        print(f"Saved {out}")

print("Done")