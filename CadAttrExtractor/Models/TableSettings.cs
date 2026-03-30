namespace CadAttrExtractor
{
    /// <summary>
    /// Settings for generating DWG tables.
    /// </summary>
    public class TableSettings
    {
        /// <summary>
        /// Row height in drawing units.
        /// </summary>
        public double RowHeight { get; set; } = 8.0;

        /// <summary>
        /// Column A width (图号/Drawing Number) in drawing units.
        /// </summary>
        public double ColumnWidthA { get; set; } = 40.0;

        /// <summary>
        /// Column B width (图名/Drawing Title) in drawing units.
        /// </summary>
        public double ColumnWidthB { get; set; } = 60.0;

        /// <summary>
        /// Column C width (版本/Version) in drawing units.
        /// </summary>
        public double ColumnWidthC { get; set; } = 15.0;

        /// <summary>
        /// Column D width (日期/Date) in drawing units.
        /// </summary>
        public double ColumnWidthD { get; set; } = 15.0;

        /// <summary>
        /// The AutoCAD text style name for table content.
        /// </summary>
        public string TextStyle { get; set; } = "Standard";

        /// <summary>
        /// Text height for table content.
        /// </summary>
        public double TextHeight { get; set; } = 3.5;

        /// <summary>
        /// Header row text (e.g., "图纸目录").
        /// </summary>
        public string HeaderText { get; set; } = "图纸目录";

        /// <summary>
        /// Whether to enable automatic pagination.
        /// </summary>
        public bool AutoPagination { get; set; } = true;

        /// <summary>
        /// Maximum number of rows per page when auto-pagination is enabled.
        /// </summary>
        public int RowsPerPage { get; set; } = 30;

        /// <summary>
        /// The number of columns in the table (excluding row index).
        /// </summary>
        public int ColumnCount => 5;

        /// <summary>
        /// Total width of all columns.
        /// </summary>
        public double TotalWidth => ColumnWidthA + ColumnWidthB + ColumnWidthC + ColumnWidthD + 5.0;

        /// <summary>
        /// Gets column headers for the table.
        /// </summary>
        public string[] ColumnHeaders => new[]
        {
            "序号",
            "图号",
            "图名",
            "版本",
            "日期"
        };

        /// <summary>
        /// Gets column widths as an array.
        /// </summary>
        public double[] ColumnWidths => new[]
        {
            5.0,  // 序号
            ColumnWidthA,
            ColumnWidthB,
            ColumnWidthC,
            ColumnWidthD
        };

        /// <summary>
        /// Creates a copy of this settings object.
        /// </summary>
        public TableSettings Clone()
        {
            return new TableSettings
            {
                RowHeight = RowHeight,
                ColumnWidthA = ColumnWidthA,
                ColumnWidthB = ColumnWidthB,
                ColumnWidthC = ColumnWidthC,
                ColumnWidthD = ColumnWidthD,
                TextStyle = TextStyle,
                TextHeight = TextHeight,
                HeaderText = HeaderText,
                AutoPagination = AutoPagination,
                RowsPerPage = RowsPerPage
            };
        }
    }
}
