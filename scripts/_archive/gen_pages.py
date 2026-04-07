import fitz
import os

pdf_path = r"D:\OpenClaw\.openclaw\workspace\temp_pdf.pdf"
output_dir = r"D:\OpenClaw\.openclaw\workspace"
start_page = 16
end_page = 88

doc = fitz.open(pdf_path)
print(f"Total pages: {doc.page_count}")

for page_num in range(start_page, end_page + 1):
    page = doc[page_num - 1]
    pix = page.get_pixmap(dpi=150)
    out_path = os.path.join(output_dir, f"temp_pdf_page_{page_num}.png")
    pix.save(out_path)
    if page_num % 5 == 0:
        print(f"Generated page {page_num}")

doc.close()
print("Done!")
