using System;
using System.Collections.Generic;

namespace CadAttrExtractor
{
    /// <summary>
    /// Settings for exporting to Excel and Word.
    /// </summary>
    public class ExportSettings
    {
        /// <summary>
        /// Path to the Excel template file.
        /// </summary>
        public string ExcelTemplatePath { get; set; }

        /// <summary>
        /// Path to the Word template file.
        /// </summary>
        public string WordTemplatePath { get; set; }

        /// <summary>
        /// The last folder used for export operations.
        /// </summary>
        public string LastExportFolder { get; set; }

        /// <summary>
        /// List of recently used attribute tags.
        /// </summary>
        public List<string> RecentAttributeTags { get; set; } = new();

        /// <summary>
        /// The attribute tag name for drawing title (图名).
        /// </summary>
        public string DrawingTitleTag { get; set; } = "图名";

        /// <summary>
        /// The attribute tag name for drawing index (图号).
        /// </summary>
        public string DrawingIndexTag { get; set; } = "图号";

        /// <summary>
        /// The attribute tag name for drawing version (版本).
        /// </summary>
        public string DrawingVersionTag { get; set; } = "版本";

        /// <summary>
        /// The attribute tag name for drawing date (日期).
        /// </summary>
        public string DrawingDateTag { get; set; } = "日期";

        /// <summary>
        /// Adds a tag to the recent tags list.
        /// </summary>
        public void AddRecentTag(string tag)
        {
            if (string.IsNullOrEmpty(tag)) return;

            RecentAttributeTags.Remove(tag);
            RecentAttributeTags.Insert(0, tag);

            if (RecentAttributeTags.Count > 10)
            {
                RecentAttributeTags.RemoveAt(10);
            }
        }

        /// <summary>
        /// Creates a copy of this settings object.
        /// </summary>
        public ExportSettings Clone()
        {
            return new ExportSettings
            {
                ExcelTemplatePath = ExcelTemplatePath,
                WordTemplatePath = WordTemplatePath,
                LastExportFolder = LastExportFolder,
                RecentAttributeTags = new List<string>(RecentAttributeTags),
                DrawingTitleTag = DrawingTitleTag,
                DrawingIndexTag = DrawingIndexTag,
                DrawingVersionTag = DrawingVersionTag,
                DrawingDateTag = DrawingDateTag
            };
        }
    }
}
