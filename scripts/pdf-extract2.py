# -*- coding: utf-8 -*-
import pdfplumber

path = r"E:\工程规范\JTGT F20-2015 公路路面基层施工技术细则.pdf"
out_path = r"D:\OpenClaw\.openclaw\workspace\scripts\pdf-extract-full.txt"

lines = []
total = 88
lines.append(f"总页数: {total}\n")

with pdfplumber.open(path) as pdf:
    # 统计每页文本/表格量
    lines.append("\n===== 页面文本量统计 =====\n")
    for i in range(len(pdf.pages)):
        text = pdf.pages[i].extract_text()
        tables = pdf.pages[i].extract_tables()
        tlen = len(text) if text else 0
        tcount = len(tables) if tables else 0
        lines.append(f"页{i+1}: 文本{tlen}字, 表格{tcount}个\n")

    # 打印前10页完整文本
    lines.append("\n===== 前10页完整内容 =====\n")
    for i in range(min(10, len(pdf.pages))):
        text = pdf.pages[i].extract_text()
        lines.append(f"--- 第{i+1}页 ---\n")
        if text:
            lines.append(text + "\n")
        else:
            lines.append("(无文本，可能是扫描件)\n")

    # 提取所有表格
    lines.append("\n===== 所有表格 =====\n")
    for i in range(len(pdf.pages)):
        tables = pdf.pages[i].extract_tables()
        if tables:
            lines.append(f"\n=== 第{i+1}页，共{len(tables)}个表 ===\n")
            for j, table in enumerate(tables):
                lines.append(f"--- 表{j+1} ---\n")
                for row in table[:30]:
                    if row:
                        lines.append(" | ".join(str(c) if c else "" for c in row) + "\n")
                if len(table) > 30:
                    lines.append(f"... 还有{len(table)-30}行\n")

with open(out_path, "w", encoding="utf-8") as f:
    f.writelines(lines)

print("Done")
