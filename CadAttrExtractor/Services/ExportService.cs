using DocumentFormat.OpenXml;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Wordprocessing;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace CadAttrExtractor
{
    /// <summary>
    /// Service for exporting extracted items to Excel and Word formats.
    /// </summary>
    public static class ExportService
    {
        /// <summary>
        /// Placeholder pattern for template replacement.
        /// </summary>
        private static readonly Regex PlaceholderPattern = new(@"\{\{(\w+)\}\}", RegexOptions.Compiled);

        /// <summary>
        /// Exports items to Excel using a template file.
        /// </summary>
        public static void ExportToExcel(
            List<ExtractedItem> items,
            string templatePath,
            string outputPath,
            ExportSettings settings)
        {
            if (!File.Exists(templatePath))
            {
                throw new FileNotFoundException($"Excel template not found: {templatePath}");
            }

            // Copy template to output location
            File.Copy(templatePath, outputPath, true);

            using var workbook = new ClosedXML.Excel.XLWorkbook(outputPath);
            var worksheet = workbook.Worksheets.First();

            // Replace placeholders in header
            ReplacePlaceholdersInSheet(worksheet, items, settings);

            // Add data rows
            InsertDynamicRows(worksheet, items, settings);

            workbook.Save();
            CadAttrExtractorApp.WriteLine($"[Export] Excel saved to {outputPath}");
        }

        /// <summary>
        /// Exports items to Excel without a template (creates new file).
        /// </summary>
        public static void ExportToExcelNew(
            List<ExtractedItem> items,
            string outputPath,
            ExportSettings settings)
        {
            using var workbook = new ClosedXML.Excel.XLWorkbook();
            var worksheet = workbook.AddWorksheet("图纸目录");

            // Add header row
            var headerRow = worksheet.Row(1);
            headerRow.Style.Font.Bold = true;
            headerRow.Style.Fill.BackgroundColor = ClosedXML.Excel.XLColor.FromRgb(0x1E, 0x88, 0xE5);
            headerRow.Style.Font.FontColor = ClosedXML.Excel.XLColor.FromHtml("#FFFFFF");

            var headers = new[] { "序号", "图号", "图名", "版本", "日期", "X坐标", "Y坐标" };
            for (int i = 0; i < headers.Length; i++)
            {
                worksheet.Cell(1, i + 1).Value = headers[i];
                worksheet.Cell(1, i + 1).Style.Alignment.Horizontal =
                    ClosedXML.Excel.XLAlignmentHorizontalValues.Center;
            }

            // Add data rows
            for (int row = 0; row < items.Count; row++)
            {
                var item = items[row];
                var excelRow = row + 2;

                worksheet.Cell(excelRow, 1).Value = row + 1;
                worksheet.Cell(excelRow, 2).Value = item.DrawingIndex ?? item.BlockName;
                worksheet.Cell(excelRow, 3).Value = item.DrawingTitle ?? item.BlockName;
                worksheet.Cell(excelRow, 4).Value = item.Attributes.GetValueOrDefault(settings.DrawingVersionTag, "-");
                worksheet.Cell(excelRow, 5).Value = item.Attributes.GetValueOrDefault(settings.DrawingDateTag, "-");
                worksheet.Cell(excelRow, 6).Value = Math.Round(item.PositionX, 2);
                worksheet.Cell(excelRow, 7).Value = Math.Round(item.PositionY, 2);

                // Alternate row colors
                if (row % 2 == 0)
                {
                    worksheet.Row(excelRow).Style.Fill.BackgroundColor =
                        ClosedXML.Excel.XLColor.FromRgb(0x3E, 0x3E, 0x42);
                    worksheet.Row(excelRow).Style.Font.FontColor =
                        ClosedXML.Excel.XLColor.FromHtml("#FFFFFF");
                }

                // Center align numeric columns
                worksheet.Cell(excelRow, 1).Style.Alignment.Horizontal =
                    ClosedXML.Excel.XLAlignmentHorizontalValues.Center;
                worksheet.Cell(excelRow, 6).Style.Alignment.Horizontal =
                    ClosedXML.Excel.XLAlignmentHorizontalValues.Right;
                worksheet.Cell(excelRow, 7).Style.Alignment.Horizontal =
                    ClosedXML.Excel.XLAlignmentHorizontalValues.Right;
            }

            // Auto-fit columns
            worksheet.Columns().AdjustToContents();

            // Add summary row
            var summaryRow = items.Count + 3;
            worksheet.Cell(summaryRow, 1).Value = $"�?{items.Count} �?;
            worksheet.Cell(summaryRow, 1).Style.Font.Bold = true;

            workbook.SaveAs(outputPath);
            CadAttrExtractorApp.WriteLine($"[Export] New Excel saved to {outputPath}");
        }

        /// <summary>
        /// Exports items to Word using a template file.
        /// </summary>
        public static void ExportToWord(
            List<ExtractedItem> items,
            string templatePath,
            string outputPath,
            ExportSettings settings)
        {
            if (!File.Exists(templatePath))
            {
                throw new FileNotFoundException($"Word template not found: {templatePath}");
            }

            // Copy template to output location
            File.Copy(templatePath, outputPath, true);

            using var document = WordprocessingDocument.Open(outputPath, true);
            var body = document.MainDocumentPart?.Document?.Body;
            if (body == null)
            {
                throw new InvalidOperationException("Invalid Word template");
            }

            // Replace placeholders
            ReplacePlaceholdersInDocument(body, items, settings);

            // Insert table
            InsertDynamicTable(body, items, settings);

            document.Save();
            CadAttrExtractorApp.WriteLine($"[Export] Word saved to {outputPath}");
        }

        /// <summary>
        /// Exports items to Word without a template (creates new document).
        /// </summary>
        public static void ExportToWordNew(
            List<ExtractedItem> items,
            string outputPath,
            ExportSettings settings)
        {
            using var document = WordprocessingDocument.Create(outputPath, WordprocessingDocumentType.Document);
            var mainPart = document.AddMainDocumentPart();
            mainPart.Document = new DocumentFormat.OpenXml.Wordprocessing.Document();
            var body = mainPart.Document.AppendChild(new Body());

            // Add title
            var title = body.AppendChild(new Paragraph());
            var titleRun = title.AppendChild(new Run());
            titleRun.AppendChild(new RunProperties(new Bold(), new FontSize { Val = "32" }));
            titleRun.AppendChild(new Text("图纸目录"));

            // Add metadata
            AddMetadataParagraph(body, $"生成时间: {DateTime.Now:yyyy-MM-dd HH:mm:ss}");
            AddMetadataParagraph(body, $"�?{items.Count} �?);

            // Add separator
            body.AppendChild(new Paragraph(new Run(new Separator())));

            // Add table
            InsertDynamicTable(body, items, settings);

            mainPart.Document.Save();
            CadAttrExtractorApp.WriteLine($"[Export] New Word saved to {outputPath}");
        }

        /// <summary>
        /// Replaces placeholders in a worksheet with actual values.
        /// </summary>
        private static void ReplacePlaceholdersInSheet(
            ClosedXML.Excel.IXLWorksheet worksheet,
            List<ExtractedItem> items,
            ExportSettings settings)
        {
            var cells = worksheet.RangeUsed()?.Cells();
            if (cells == null) return;

            foreach (var cell in cells)
            {
                var value = cell.Value?.ToString() ?? string.Empty;
                if (string.IsNullOrEmpty(value)) continue;

                var newValue = ReplacePlaceholders(value, items, settings);
                if (newValue != value)
                {
                    cell.Value = newValue;
                }
            }
        }

        /// <summary>
        /// Replaces placeholders in a Word document.
        /// </summary>
        private static void ReplacePlaceholdersInDocument(
            Body body,
            List<ExtractedItem> items,
            ExportSettings settings)
        {
            foreach (var text in body.Descendants<Text>())
            {
                var parent = text.Parent;
                if (parent is Run run && run.Parent is Paragraph para)
                {
                    var value = text.Text;
                    var newValue = ReplacePlaceholders(value, items, settings);
                    if (newValue != value)
                    {
                        text.Text = newValue;
                    }
                }
            }
        }

        /// <summary>
