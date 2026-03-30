# -*- coding: utf-8 -*-
"""
PDF Report Generator - Python backend using reportlab + fpdf2
"""
import sys
import os
import argparse
from datetime import datetime

try:
    from reportlab.lib.pagesizes import A4, letter
    from reportlab.lib import colors
    from reportlab.lib.units import inch, cm
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, Image
    from reportlab.platypus.flowables import HRFlowable
    from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT, TA_JUSTIFY
except ImportError:
    print("ERROR: reportlab not installed. Run: pip install reportlab")
    sys.exit(1)

try:
    from fpdf import FPDF
except ImportError:
    print("WARNING: fpdf2 not installed. Some features may not work. Run: pip install fpdf2")
    FPDF = None


def create_pdf_report(title, content, output="output.pdf", author="System",
                      font_size=12, margin=1*inch):
    """Create a PDF report using ReportLab."""
    doc = SimpleDocTemplate(output, pagesize=A4, 
                            leftMargin=margin, rightMargin=margin,
                            topMargin=margin, bottomMargin=margin)
    
    styles = getSampleStyleSheet()
    
    # Custom styles
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=24,
        textColor=colors.HexColor('#333333'),
        spaceAfter=30,
        alignment=TA_CENTER
    )
    
    heading_style = ParagraphStyle(
        'CustomHeading',
        parent=styles['Heading2'],
        fontSize=16,
        textColor=colors.HexColor('#444444'),
        spaceAfter=12,
        spaceBefore=12
    )
    
    body_style = ParagraphStyle(
        'CustomBody',
        parent=styles['Normal'],
        fontSize=font_size,
        leading=font_size * 1.5,
        alignment=TA_JUSTIFY,
        spaceAfter=12
    )
    
    story = []
    
    # Title
    story.append(Paragraph(title, title_style))
    story.append(Spacer(1, 0.2*inch))
    
    # Metadata
    meta_style = ParagraphStyle('Meta', parent=styles['Normal'],
                                 fontSize=10, textColor=colors.grey,
                                 alignment=TA_CENTER)
    story.append(Paragraph(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} | Author: {author}", meta_style))
    story.append(Spacer(1, 0.3*inch))
    story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor('#CCCCCC')))
    story.append(Spacer(1, 0.3*inch))
    
    # Content
    if isinstance(content, str):
        paragraphs = content.split('\n\n')
        for para in paragraphs:
            para = para.strip()
            if para.startswith('# '):
                story.append(Paragraph(para[2:], title_style))
            elif para.startswith('## '):
                story.append(Paragraph(para[3:], heading_style))
            elif para.startswith('### '):
                story.append(Paragraph(para[4:], styles['Heading3']))
            elif para:
                story.append(Paragraph(para, body_style))
            story.append(Spacer(1, 0.1*inch))
    else:
        story.append(Paragraph(str(content), body_style))
    
    doc.build(story)
    return output


def create_pdf_with_table(data, headers, output="table.pdf", title="Report"):
    """Create a PDF with a table."""
    doc = SimpleDocTemplate(output, pagesize=A4)
    story = []
    
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle('Title', parent=styles['Heading1'],
                                  fontSize=20, alignment=TA_CENTER)
    story.append(Paragraph(title, title_style))
    story.append(Spacer(1, 0.3*inch))
    
    # Create table
    table_data = [headers] + data
    table = Table(table_data)
    
    style = TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#4472C4')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 12),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
        ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
        ('GRID', (0, 0), (-1, -1), 1, colors.black)
    ])
    
    # Alternate row colors
    for i in range(1, len(table_data)):
        if i % 2 == 0:
            style.add('BACKGROUND', (0, i), (-1, i), colors.lightgrey)
    
    table.setStyle(style)
    story.append(table)
    
    doc.build(story)
    return output


def html_to_pdf(input_html, output_pdf):
    """Convert HTML to PDF using fpdf2 or basic text."""
    if FPDF:
        pdf = FPDF()
        pdf.add_page()
        pdf.set_auto_page_break(auto=True, margin=15)
        
        with open(input_html, 'r', encoding='utf-8') as f:
            html_content = f.read()
        
        # Simple HTML parsing - extract text between tags
        import re
        text = re.sub(r'<style[^>]*>.*?</style>', '', html_content, flags=re.DOTALL)
        text = re.sub(r'<[^>]+>', '', text)
        text = re.sub(r'\n\s*\n', '\n\n', text)
        
        pdf.set_font("Arial", size=12)
        for line in text.strip().split('\n'):
            if line.strip():
                pdf.multi_cell(0, 8, line.strip())
                pdf.ln(2)
        
        pdf.output(output_pdf)
        return output_pdf
    else:
        print("ERROR: fpdf2 not installed. Cannot convert HTML to PDF.")
        sys.exit(1)


def extract_text_from_pdf(input_pdf, output_txt):
    """Extract text from PDF."""
    try:
        import PyPDF2
    except ImportError:
        print("ERROR: PyPDF2 not installed for text extraction. Run: pip install PyPDF2")
        # Fallback: just copy file
        with open(input_pdf, 'rb') as f:
            content = f.read()
        with open(output_txt, 'wb') as f:
            f.write(content)
        return output_txt
    
    with open(input_pdf, 'rb') as f:
        reader = PyPDF2.PdfReader(f)
        text_parts = []
        for page in reader.pages:
            text_parts.append(page.extract_text())
    
    full_text = "\n\n".join(text_parts)
    
    with open(output_txt, 'w', encoding='utf-8') as f:
        f.write(full_text)
    
    return output_txt


def main():
    parser = argparse.ArgumentParser(description="PDF Report Generator")
    parser.add_argument("action", choices=["create", "table", "html2pdf", "extract"])
    parser.add_argument("--title", "-t", default="Report")
    parser.add_argument("--content", "-c")
    parser.add_argument("--input", "-i")
    parser.add_argument("--output", "-o", default="output.pdf")
    parser.add_argument("--author", default="System")
    parser.add_argument("--font-size", type=int, default=12)
    parser.add_argument("--headers", nargs="+")
    parser.add_argument("--data", nargs="+")
    
    args = parser.parse_args()
    
    if args.action == "create":
        content = args.content or "No content provided."
        result = create_pdf_report(args.title, content, args.output, args.author, args.font_size)
        print(f"PDF created: {result}")
    
    elif args.action == "table":
        headers = args.headers or ["Column 1", "Column 2", "Column 3"]
        data = []
        if args.data:
            for item in args.data:
                data.append(item.split(","))
        result = create_pdf_with_table(data, headers, args.output, args.title)
        print(f"Table PDF created: {result}")
    
    elif args.action == "html2pdf":
        result = html_to_pdf(args.input, args.output)
        print(f"HTML converted to PDF: {result}")
    
    elif args.action == "extract":
        result = extract_text_from_pdf(args.input, args.output)
        print(f"Text extracted to: {result}")


if __name__ == "__main__":
    main()
