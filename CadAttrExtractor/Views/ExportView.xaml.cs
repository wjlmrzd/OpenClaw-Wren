using Microsoft.Win32;
using System.Windows;
using System.Windows.Controls;

namespace CadAttrExtractor.Views
{
    /// <summary>
    /// Export view with template selection and Excel/Word/CSV export.
    /// </summary>
    public partial class ExportView : UserControl
    {
        public ExportView()
        {
            InitializeComponent();
        }

        private void BrowseExcelTemplate_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new OpenFileDialog
            {
                Filter = "Excel Files (*.xlsx)|*.xlsx|All Files (*.*)|*.*",
                Title = "选择 Excel 模板"
            };

            if (dialog.ShowDialog() == true)
            {
                if (DataContext is ViewModels.MainViewModel vm)
                {
                    vm.ExcelTemplatePath = dialog.FileName;
                }
            }
        }

        private void BrowseWordTemplate_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new OpenFileDialog
            {
                Filter = "Word Files (*.docx)|*.docx|All Files (*.*)|*.*",
                Title = "选择 Word 模板"
            };

            if (dialog.ShowDialog() == true)
            {
                if (DataContext is ViewModels.MainViewModel vm)
                {
                    vm.WordTemplatePath = dialog.FileName;
                }
            }
        }
    }
}
