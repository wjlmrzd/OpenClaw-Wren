using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using System;
using System.Collections.Generic;
using System.Linq;

namespace CadAttrExtractor
{
    /// <summary>
    /// Service for generating AutoCAD tables from extracted items.
    /// </summary>
    public static class TableGenerationService
    {
        private const string TableStyleName = "CadAttrExtractorStyle";
        private const int HeaderRow = 0;
        private const int DataStartRow = 1;

        /// <summary>
        /// Generates a table in the AutoCAD drawing.
        /// </summary>
        /// <param name="db">The database.</param>
        /// <param name="items">The extracted items to include in the table.</param>
        /// <param name="startPoint">The insertion point for the table.</param>
        /// <param name="settings">Table generation settings.</param>
        /// <returns>The generated table (or tables if paginated).</returns>
        public static List<Table> GenerateTable(
            Database db,
            List<ExtractedItem> items,
            Point3d startPoint,
            TableSettings settings)
        {
            var tables = new List<Table>();

            if (items == null || items.Count == 0)
            {
                CadAttrExtractorApp.WriteLine("[Table] No items to generate table");
                return tables;
            }

            // Create or update table style
            TransactionHelper.Execute(db, trans =>
            {
                CreateTableStyle(db, trans, settings);
            });

            // Handle pagination if enabled
            if (settings.AutoPagination && items.Count > settings.RowsPerPage)
            {
                tables = GeneratePaginatedTables(db, items, startPoint, settings);
            }
            else
            {
                var table = GenerateSingleTable(db, items, startPoint, settings);
                if (table != null)
                {
                    tables.Add(table);
                }
            }

            CadAttrExtractorApp.WriteLine($"[Table] Generated {tables.Count} table(s) with {items.Count} rows");
            return tables;
        }

        /// <summary>
        /// Generates paginated tables.
        /// </summary>
        private static List<Table> GeneratePaginatedTables(
            Database db,
            List<ExtractedItem> items,
            Point3d startPoint,
            TableSettings settings)
        {
            var tables = new List<Table>();
            var pageCount = (int)Math.Ceiling((double)items.Count / settings.RowsPerPage);
            var currentPoint = startPoint;

            for (int page = 0; page < pageCount; page++)
            {
                var pageItems = items
                    .Skip(page * settings.RowsPerPage)
                    .Take(settings.RowsPerPage)
                    .ToList();

                var table = GenerateSingleTable(db, pageItems, currentPoint, settings, page + 1, pageCount);
                if (table != null)
                {
                    tables.Add(table);
                    // Move insertion point down for next page
                    currentPoint = new Point3d(
                        currentPoint.X,
                        currentPoint.Y - table.Height - 10,
                        currentPoint.Z);
                }
            }

            return tables;
        }

        /// <summary>
        /// Generates a single table.
        /// </summary>
        private static Table GenerateSingleTable(
            Database db,
            List<ExtractedItem> items,
            Point3d startPoint,
            TableSettings settings,
            int currentPage = 1,
            int totalPages = 1)
        {
            Table table = null;

            TransactionHelper.Execute(db, trans =>
            {
                table = CreateTable(db, trans, items, startPoint, settings, currentPage, totalPages);
            });

            return table;
        }

        /// <summary>
        /// Creates the table object.
        /// </summary>
        private static Table CreateTable(
            Database db,
            Transaction trans,
            List<ExtractedItem> items,
            Point3d startPoint,
            TableSettings settings,
            int currentPage = 1,
            int totalPages = 1)
        {
            var table = new Table
            {
                Position = startPoint,
                TableStyle = db.TableStyleDictionaryId,
                Layer = "0"
            };

            // Set table style
            try
            {
                table.SetTableStyleOverride(TableStyleName, db);
            }
            catch
            {
                // Style might not exist, use default
            }

            // Calculate dimensions
            var (rows, columns) = CalculateTableDimensions(items.Count, settings);

            table.InsertRows(0, settings.RowHeight, rows);
            table.InsertColumns(0, settings.ColumnWidths.Sum(), columns);

            // Set column widths
            var xPos = 0.0;
            for (int i = 0; i < columns; i++)
            {
                table.Columns[i].Width = settings.ColumnWidths[i];
            }

            // Add header row
            PopulateHeaderRow(table, settings);

            // Add data rows
            PopulateDataRows(table, items, settings);

            // Set cell styles and content
            ApplyCellStyles(table, settings);

            // Insert into model space
            InsertTable(db, trans, table, startPoint);

            return table;
        }

        /// <summary>
        /// Populates the header row with column names.
        /// </summary>
        private static void PopulateHeaderRow(Table table, TableSettings settings)
        {
            var headers = settings.ColumnHeaders;
            for (int col = 0; col < headers.Length; col++)
            {
                var cell = table.Cells[HeaderRow, col];
                cell.TextString = headers[col];
                cell.Alignment = CellAlignment.MiddleCenter;

                // Set header background color (dark)
                cell.BackgroundColor = Autodesk.AutoCAD.Colors.Color.FromRgb(0x2D, 0x2D, 0x30);
                cell.TextColor = Autodesk.AutoCAD.Colors.Color.FromRgb(0xFF, 0xFF, 0xFF);
            }
        }

        /// <summary>
        /// Populates data rows with extracted item values.
        /// </summary>
        private static void PopulateDataRows(Table table, List<ExtractedItem> items, TableSettings settings)
        {
            for (int row = 0; row < items.Count; row++)
            {
                var item = items[row];
                var tableRow = row + DataStartRow;

                // Row number
                table.Cells[tableRow, 0].TextString = (row + 1).ToString();
                table.Cells[tableRow, 0].Alignment = CellAlignment.MiddleCenter;

                // Drawing number (index)
                var drawingNo = !string.IsNullOrEmpty(item.DrawingIndex)
                    ? item.DrawingIndex
                    : item.BlockName;
                table.Cells[tableRow, 1].TextString = drawingNo;
                table.Cells[tableRow, 1].Alignment = CellAlignment.MiddleLeft;

                // Drawing title
                var title = !string.IsNullOrEmpty(item.DrawingTitle)
                    ? item.DrawingTitle
                    : item.BlockName;
                table.Cells[tableRow, 2].TextString = title;
                table.Cells[tableRow, 2].Alignment = CellAlignment.MiddleLeft;

                // Version - try to get from attributes
                var version = item.Attributes.TryGetValue("版本", out var v) ? v : "-";
                table.Cells[tableRow, 3].TextString = version;
                table.Cells[tableRow, 3].Alignment = CellAlignment.MiddleCenter;

                // Date - try to get from attributes
                var date = item.Attributes.TryGetValue("日期", out var d) ? d : "-";
                table.Cells[tableRow, 4].TextString = date;
                table.Cells[tableRow, 4].Alignment = CellAlignment.MiddleCenter;
            }
        }

        /// <summary>
        /// Applies cell styles to the table.
        /// </summary>
        private static void ApplyCellStyles(Table table, TableSettings settings)
        {
            // Set text height and style for all cells
            for (int row = 0; row < table.Rows.Count; row++)
            {
                for (int col = 0; col < table.Columns.Count; col++)
                {
                    var cell = table.Cells[row, col];
                    cell.TextHeight = settings.TextHeight;

                    // Alternate row colors for data rows
                    if (row > HeaderRow)
                    {
                        if (row % 2 == 0)
                        {
                            cell.BackgroundColor = Autodesk.AutoCAD.Colors.Color.FromRgb(0x3E, 0x3E, 0x42);
                        }
                        else
                        {
                            cell.BackgroundColor = Autodesk.AutoCAD.Colors.Color.FromRgb(0x2D, 0x2D, 0x30);
                        }
                        cell.TextColor = Autodesk.AutoCAD.Colors.Color.FromRgb(0xFF, 0xFF, 0xFF);
                    }

                    // Set margins
                    cell.Margin = new CellMargin(1, 1, 1, 1);
                }
            }
        }

        /// <summary>
        /// Calculates the required table dimensions.
        /// </summary>
        public static (int Rows, int Columns) CalculateTableDimensions(int itemCount, TableSettings settings)
        {
            var rows = itemCount + 1; // +1 for header
            var columns = settings.ColumnCount;
            return (rows, columns);
        }

        /// <summary>
        /// Creates or updates the table style.
        /// </summary>
        public static void CreateTableStyle(Database db, Transaction trans, TableSettings settings)
        {
            var styleDict = (DictionaryManager)trans.GetObject(
                db.TableStyleDictionaryId, OpenMode.ForRead);

            if (styleDict.Contains(TableStyleName))
            {
                // Update existing style
                var styleId = styleDict[TableStyleName];
                var style = (TableStyle)trans.GetObject(styleId, OpenMode.ForWrite);
                ConfigureTableStyle(style, settings);
            }
            else
            {
                // Create new style
                var styleId = ObjectId.Null;
                styleDict.UpgradeOpen();

                var style = new TableStyle
                {
                    Name = TableStyleName
                };

                ConfigureTableStyle(style, settings);

                styleId = styleDict.AddRecord(style);
                trans.AddNewlyCreatedDBObject(style, true);
            }
        }

        /// <summary>
        /// Configures a table style with the given settings.
        /// </summary>
        private static void ConfigureTableStyle(TableStyle style, TableSettings settings)
        {
            style.TextHeight = settings.TextHeight;
            style.RowHeight = settings.RowHeight;
            style.FlowDirection = FlowDirection.T2B;
            style.HorizontalCellMargin = 1.0;
            style.VerticalCellMargin = 1.0;
        }

        /// <summary>
        /// Inserts the table into model space.
        /// </summary>
        public static void InsertTable(Database db, Transaction trans, Table table, Point3d position)
        {
            var msId = SymbolUtilityServices.GetBlockModelSpaceId(db);
            var ms = (BlockTableRecord)trans.GetObject(msId, OpenMode.ForWrite);

            table.Position = position;
            ms.AppendEntity(table);
            trans.AddNewlyCreatedDBObject(table, true);
        }

        /// <summary>
        /// Handles pagination logic for tables.
        /// </summary>
        public static List<List<ExtractedItem>> HandlePagination(
            List<ExtractedItem> items,
            TableSettings settings)
        {
            var pages = new List<List<ExtractedItem>>();

            if (!settings.AutoPagination || items.Count <= settings.RowsPerPage)
            {
                pages.Add(items);
                return pages;
            }

            for (int i = 0; i < items.Count; i += settings.RowsPerPage)
            {
                var pageItems = items.Skip(i).Take(settings.RowsPerPage).ToList();
                pages.Add(pageItems);
            }

            return pages;
        }
    }
}
