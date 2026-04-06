using System.Windows;
using Microsoft.Win32;
using CadAttrExtractor.Models;
using CadAttrExtractor.Services;

namespace CadAttrExtractor.Views
{
    /// <summary>
    /// Interaction logic for SettingsDialog.xaml
    /// </summary>
    public partial class SettingsDialog : Window
    {
        private readonly AppSettings _settings;

        public SettingsDialog()
        {
            InitializeComponent();

            _settings = SettingsService.Instance.Current;
            LoadSettings();

            CadAttrExtractorApp.WriteLine("[SettingsDialog] Opened");
        }

        private void LoadSettings()
        {
            // Extraction settings
            ToleranceTextBox.Text = _settings.Extraction.Tolerance.ToString();
            IncludeAnonymousCheckBox.IsChecked = _settings.Extraction.IncludeAnonymousBlocks;
            RegexPatternsTextBox.Text = string.Join("\n", _settings.Extraction.TitleRegexPatterns);

            // Table settings
            var tableSettings = _settings.Table;
            RowHeightTextBox.Text = tableSettings.RowHeight.ToString();
            ColumnWidthTextBox.Text = tableSettings.ColumnWidth.ToString();
            TextHeightTextBox.Text = tableSettings.TextHeight.ToString();
            RowsPerPageTextBox.Text = tableSettings.RowsPerPage.ToString();
            AutoPaginateCheckBox.IsChecked = tableSettings.AutoPaginate;

            // Export settings
            var exportSettings = _settings.Export;
            ExcelTemplateTextBox.Text = exportSettings.ExcelTemplatePath ?? "";
            WordTemplateTextBox.Text = exportSettings.WordTemplatePath ?? "";
            TitleTagTextBox.Text = exportSettings.DrawingTitleTag;
            IndexTagTextBox.Text = exportSettings.DrawingIndexTag;
            VersionTagTextBox.Text = exportSettings.DrawingVersionTag;
            DateTagTextBox.Text = exportSettings.DrawingDateTag;

            // UI settings
            var uiSettings = _settings.UI;
            AutoShowPaletteCheckBox.IsChecked = uiSettings.AutoShowPalette;
            ConfirmExtractCheckBox.IsChecked = uiSettings.ConfirmBeforeExtract;
            RememberSortModeCheckBox.IsChecked = uiSettings.RememberLastSortMode;
        }

        private void SaveSettings()
        {
            // Extraction settings
            if (double.TryParse(ToleranceTextBox.Text, out double tolerance))
                _settings.Extraction.Tolerance = tolerance;
            _settings.Extraction.IncludeAnonymousBlocks = IncludeAnonymousCheckBox.IsChecked ?? true;

            var patterns = RegexPatternsTextBox.Text
                .Split(new[] { '\r', '\n' }, System.StringSplitOptions.RemoveEmptyEntries);
            _settings.Extraction.TitleRegexPatterns = new System.Collections.Generic.List<string>(patterns);

            // Table settings
            var tableSettings = _settings.Table;
            if (double.TryParse(RowHeightTextBox.Text, out double rowHeight))
                tableSettings.RowHeight = rowHeight;
            if (double.TryParse(ColumnWidthTextBox.Text, out double columnWidth))
                tableSettings.ColumnWidth = columnWidth;
            if (double.TryParse(TextHeightTextBox.Text, out double textHeight))
                tableSettings.TextHeight = textHeight;
            if (int.TryParse(RowsPerPageTextBox.Text, out int rowsPerPage))
                tableSettings.RowsPerPage = rowsPerPage;
            tableSettings.AutoPaginate = AutoPaginateCheckBox.IsChecked ?? true;

            // Export settings
            _settings.Export.ExcelTemplatePath = ExcelTemplateTextBox.Text;
            _settings.Export.WordTemplatePath = WordTemplateTextBox.Text;
            _settings.Export.DrawingTitleTag = TitleTagTextBox.Text;
            _settings.Export.DrawingIndexTag = IndexTagTextBox.Text;
            _settings.Export.DrawingVersionTag = VersionTagTextBox.Text;
            _settings.Export.DrawingDateTag = DateTagTextBox.Text;

            // UI settings
            _settings.UI.AutoShowPalette = AutoShowPaletteCheckBox.IsChecked ?? true;
            _settings.UI.ConfirmBeforeExtract = ConfirmExtractCheckBox.IsChecked ?? true;
            _settings.UI.RememberLastSortMode = RememberSortModeCheckBox.IsChecked ?? true;

            // Save to file
            SettingsService.Instance.Save();

            CadAttrExtractorApp.WriteLine("[SettingsDialog] Settings saved");
        }

        private void BrowseExcelTemplate_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new OpenFileDialog
            {
                Filter = "Excel Files (*.xlsx)|*.xlsx",
                Title = "选择 Excel 模板"
            };

            if (dialog.ShowDialog() == true)
            {
                ExcelTemplateTextBox.Text = dialog.FileName;
            }
        }

        private void BrowseWordTemplate_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new OpenFileDialog
            {
                Filter = "Word Files (*.docx)|*.docx",
                Title = "选择 Word 模板"
            };

            if (dialog.ShowDialog() == true)
            {
                WordTemplateTextBox.Text = dialog.FileName;
            }
        }

        private void SaveButton_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                SaveSettings();
                DialogResult = true;
                Close();
            }
            catch (System.Exception ex)
            {
                MessageBox.Show($"保存设置失败: {ex.Message}", "错误",
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void CancelButton_Click(object sender, RoutedEventArgs e)
        {
            DialogResult = false;
            Close();
        }

        private void ResetButton_Click(object sender, RoutedEventArgs e)
        {
            var result = MessageBox.Show("确定要重置所有设置为默认值吗？",
                "确认重置", MessageBoxButton.YesNo, MessageBoxImage.Question);

            if (result == MessageBoxResult.Yes)
            {
                SettingsService.Instance.ResetToDefault();
                LoadSettings();
            }
        }
    }
}
