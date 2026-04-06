using System;
using System.Collections.Generic;

namespace CadAttrExtractor
{
    /// <summary>
    /// Root settings class containing all plugin settings.
    /// </summary>
    public class AppSettings
    {
        /// <summary>
        /// Export-related settings.
        /// </summary>
        public ExportSettings Export { get; set; } = new();

        /// <summary>
        /// Table generation settings.
        /// </summary>
        public TableSettings Table { get; set; } = new();

        /// <summary>
        /// Extraction-related settings.
        /// </summary>
        public ExtractionSettings Extraction { get; set; } = new();

        /// <summary>
        /// User interface settings.
        /// </summary>
        public UIsettings UI { get; set; } = new();

        /// <summary>
        /// Last modification timestamp.
        /// </summary>
        public DateTime LastModified { get; set; } = DateTime.Now;

        /// <summary>
        /// Settings version for migration support.
        /// </summary>
        public string Version { get; set; } = "1.0.0";

        /// <summary>
        /// Creates a default settings instance.
        /// </summary>
        public static AppSettings CreateDefault()
        {
            return new AppSettings
            {
                Export = new ExportSettings(),
                Table = new TableSettings(),
                Extraction = new ExtractionSettings(),
                UI = new UIsettings(),
                LastModified = DateTime.Now,
                Version = "1.0.0"
            };
        }
    }

    /// <summary>
    /// Settings related to attribute extraction.
    /// </summary>
    public class ExtractionSettings
    {
        /// <summary>
        /// Tolerance for coordinate-based sorting.
        /// </summary>
        public double Tolerance { get; set; } = 1.0;

        /// <summary>
        /// Whether to include anonymous blocks in extraction.
        /// </summary>
        public bool IncludeAnonymousBlocks { get; set; } = true;

        /// <summary>
        /// Whether to show progress during extraction.
        /// </summary>
        public bool ShowProgress { get; set; } = true;

        /// <summary>
        /// Regex patterns for extracting title/index/total from text.
        /// </summary>
        public List<string> TitleRegexPatterns { get; set; } = new()
        {
            @"(?<Title>.*)[\(（](?<Index>\d+)[\)）]$",
            @"(?<Title>.*)第\s*(?<Index>\d+)\s*�?*共\s*(?<Total>\d+)\s*�?,
            @"(?<Title>.*?)[\-_](?<Index>\d+)$",
            @"(?<Title>.+)"
        };

        /// <summary>
        /// Creates a copy of this settings object.
        /// </summary>
        public ExtractionSettings Clone()
        {
            return new ExtractionSettings
            {
                Tolerance = Tolerance,
                IncludeAnonymousBlocks = IncludeAnonymousBlocks,
                ShowProgress = ShowProgress,
                TitleRegexPatterns = new List<string>(TitleRegexPatterns)
            };
        }
    }

    /// <summary>
    /// User interface settings.
    /// </summary>
    public class UIsettings
    {
        /// <summary>
        /// Whether to automatically show the palette on startup.
        /// </summary>
        public bool AutoShowPalette { get; set; } = true;

        /// <summary>
        /// Whether to show preview functionality.
        /// </summary>
        public bool ShowPreviewInPalette { get; set; } = true;

        /// <summary>
        /// Whether to confirm before extraction.
        /// </summary>
        public bool ConfirmBeforeExtract { get; set; } = true;

        /// <summary>
        /// Whether to remember the last sort mode.
        /// </summary>
        public bool RememberLastSortMode { get; set; } = true;

        /// <summary>
        /// The last used sort mode.
        /// </summary>
        public SortMode LastSortMode { get; set; } = SortMode.TopToBottomLeftToRight;

        /// <summary>
        /// The current theme name ("LightTheme" or "DarkTheme").
        /// </summary>
        public string Theme { get; set; } = "LightTheme";

        /// <summary>
        /// Creates a copy of this settings object.
        /// </summary>
        public UIsettings Clone()
        {
            return new UIsettings
            {
                AutoShowPalette = AutoShowPalette,
                ShowPreviewInPalette = ShowPreviewInPalette,
                ConfirmBeforeExtract = ConfirmBeforeExtract,
                RememberLastSortMode = RememberLastSortMode,
                LastSortMode = LastSortMode,
                Theme = Theme
            };
        }
    }
}
