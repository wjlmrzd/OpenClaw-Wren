using System;
using System.Collections.Generic;

namespace CadAttrExtractor
{
    /// <summary>
    /// Represents the result of an extraction operation.
    /// </summary>
    public class ExtractionResult
    {
        /// <summary>
        /// The list of extracted items.
        /// </summary>
        public List<ExtractedItem> Items { get; set; } = new();

        /// <summary>
        /// The total count of extracted items.
        /// </summary>
        public int TotalCount => Items.Count;

        /// <summary>
        /// The number of grouped items (when items are grouped by title).
        /// </summary>
        public int GroupedCount { get; set; }

        /// <summary>
        /// The timestamp when extraction was performed.
        /// </summary>
        public DateTime ExtractedAt { get; set; } = DateTime.Now;

        /// <summary>
        /// The layer filter used for extraction.
        /// </summary>
        public string LayerFilter { get; set; }

        /// <summary>
        /// The block name pattern used for filtering.
        /// </summary>
        public string BlockNameFilter { get; set; }

        /// <summary>
        /// The attribute tag filter used.
        /// </summary>
        public string AttributeTagFilter { get; set; }

        /// <summary>
        /// The duration of the extraction operation.
        /// </summary>
        public TimeSpan ExtractionDuration { get; set; }

        /// <summary>
        /// Whether the extraction was successful.
        /// </summary>
        public bool Success { get; set; } = true;

        /// <summary>
        /// Error message if extraction failed.
        /// </summary>
        public string ErrorMessage { get; set; }

        /// <summary>
        /// Gets a summary string of the extraction result.
        /// </summary>
        public string Summary => $"提取完成: {TotalCount} �? +
            (ExtractionDuration.TotalSeconds > 0 ? $", 耗时 {ExtractionDuration.TotalSeconds:F2}�? : "");

        /// <summary>
        /// Creates a failure result.
        /// </summary>
        public static ExtractionResult Failure(string errorMessage)
        {
            return new ExtractionResult
            {
                Success = false,
                ErrorMessage = errorMessage,
                ExtractedAt = DateTime.Now
            };
        }
    }
}
