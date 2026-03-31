# -*- coding: utf-8 -*-
import pypdfium2 as pdfium
from PIL import Image
import os

path = r"E:\工程规范\JTGT F20-2015 公路路面基层施工技术细则.pdf"
out_dir = r"D:\OpenClaw\.openclaw\workspace\scripts\pdf-preview"
os.makedirs(out_dir, exist_ok=True)

pdf = pdfium.PdfDocument(path)
n = len(pdf)

# 渲染剩余重要页面
# 根据目录：
# 原材料要求 (第4页目录) -> 正文大约从第9页开始
# 3.6粗集料: ~第13页开始
# 3.7细集料: ~第16页开始
# 3.8材料分档: ~第18页开始
# 4.5推荐级配及技术要求: ~第28页开始
# 附录A 级配设计: ~第70页开始

# 已提取了前21页，继续提取22-45页
page_indices = [21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44]

for idx in page_indices:
    if idx >= n:
        continue
    page = pdf[idx]
    pil_page = page.render(scale=1.5, rotation=0)
    img = pil_page.to_pil()
    out = os.path.join(out_dir, f"page_{idx+1:02d}.png")
    img.save(out)
    print(f"Saved {out}")

print(f"Done. Total pages rendered.")
