namespace CadAttrExtractor
{
    /// <summary>
    /// Specifies the sorting mode for extracted items.
    /// </summary>
    public enum SortMode
    {
        /// <summary>
        /// Sort by Y descending (top to bottom), then X ascending (left to right).
        /// Ideal for vertical drawing lists.
        /// </summary>
        TopToBottomLeftToRight,

        /// <summary>
        /// Sort by X ascending (left to right), then Y descending (top to bottom).
        /// Ideal for horizontal drawing lists.
        /// </summary>
        LeftToRightTopToBottom,

        /// <summary>
        /// Sort by X ascending (left to right), then Y ascending (bottom to top).
        /// Reads from bottom-left to top-right.
        /// </summary>
        LeftToRightBottomToTop,

        /// <summary>
        /// Sort by original selection order (as selected by user).
        /// </summary>
        SelectionOrder
    }

    /// <summary>
    /// Extension methods for SortMode.
    /// </summary>
    public static class SortModeExtensions
    {
        /// <summary>
        /// Gets the display name for a sort mode.
        /// </summary>
        public static string GetDisplayName(this SortMode mode)
        {
            return mode switch
            {
                SortMode.TopToBottomLeftToRight => "从上到下，从左到�?,
                SortMode.LeftToRightTopToBottom => "从左到右，从上到�?,
                SortMode.LeftToRightBottomToTop => "从左到右，从下到�?,
                SortMode.SelectionOrder => "按选择顺序",
                _ => mode.ToString()
            };
        }

        /// <summary>
        /// Gets a short description for the sort mode.
        /// </summary>
        public static string GetDescription(this SortMode mode)
        {
            return mode switch
            {
                SortMode.TopToBottomLeftToRight => "适合纵向图纸目录",
                SortMode.LeftToRightTopToBottom => "适合横向图纸目录",
                SortMode.LeftToRightBottomToTop => "适合逆向阅读顺序",
                SortMode.SelectionOrder => "保持原始选择顺序",
                _ => string.Empty
            };
        }
    }
}
