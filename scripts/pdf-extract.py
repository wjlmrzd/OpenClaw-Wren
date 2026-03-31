# -*- coding: utf-8 -*-
import pdfplumber
import sys
import json

path = r"E:\工程规范\JTGT F20-2015 公路路面基层施工技术细则.pdf"
out_path = r"D:\OpenClaw\.openclaw\workspace\scripts\pdf-extract-output.txt"

results = []

with pdfplumber.open(path) as pdf:
    total = len(pdf.pages)
    results.append(f"总页数: {total}\n")

    # 提取目录（前15页）
    results.append("\n===== 目录（前15页）=====\n")
    for i in range(min(15, total)):
        text = pdf.pages[i].extract_text()
        if text:
            results.append(f"--- 第{i+1}页 ---\n")
            results.append(text[:2000] + "\n")

    # 提取前几章（30-80页）
    results.append("\n===== 第1-3章内容（页30-80）=====\n")
    for i in range(30, min(80, total)):
        text = pdf.pages[i].extract_text()
        if text and len(text.strip()) > 50:
            results.append(f"--- 第{i+1}页 ---\n")
            results.append(text[:2000] + "\n")

    # 提取表格
    results.append("\n===== 表格提取 =====\n")
    for i in range(0, min(88, total)):
        tables = pdf.pages[i].extract_tables()
        if tables:
            for j, table in enumerate(tables):
                results.append(f"--- 第{i+1}页 表{j+1} ---\n")
                for row in table[:25]:
                    results.append(str(row) + "\n")
                results.append("\n")

with open(out_path, "w", encoding="utf-8") as f:
    f.writelines(results)

print(f"Done. Written to {out_path}")
