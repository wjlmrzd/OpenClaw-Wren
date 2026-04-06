using Autodesk.AutoCAD.ApplicationServices;
using Microsoft.Win32;
using System.Windows;
using System.Windows.Controls;
using CadAttrExtractor.ViewModels;

namespace CadAttrExtractor.Views
{
    /// <summary>
    /// Settings view with extraction, table, export, and UI settings.
    /// </summary>
    public partial class SettingsView : UserControl
    {
        public SettingsView()
        {
            InitializeComponent();
            Loaded += SettingsView_Loaded;
        }

        private void SettingsView_Loaded(object sender, RoutedEventArgs e)
        {
            // Initialize theme combo based on current setting
            if (DataContext is SettingsViewModel vm)
            {
                // Theme is stored in UI settings, check current resource dict
                var app = Application.Current;
                if (app?.Resources?.MergedDictionaries != null)
                {
                    foreach (var dict in app.Resources.MergedDictionaries)
                    {
                        if (dict.Source != null && dict.Source.OriginalString.Contains("DarkTheme"))
                        {
                            ThemeComboBox.SelectedIndex = 1;
                            break;
                        }
                    }
                }
            }
        }

        private void ThemeComboBox_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (ThemeComboBox.SelectedIndex == 0)
            {
                ThemeHelper.ApplyTheme("LightTheme");
            }
            else
            {
                ThemeHelper.ApplyTheme("DarkTheme");
            }
        }

        private void BrowseExcelPath_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new OpenFileDialog
            {
                Filter = "Excel Files (*.xlsx)|*.xlsx|All Files (*.*)|*.*",
                Title = "选择 Excel 模板"
            };

            if (dialog.ShowDialog() == true && DataContext is SettingsViewModel vm)
            {
                vm.ExcelTemplatePath = dialog.FileName;
            }
        }

        private void BrowseWordPath_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new OpenFileDialog
            {
                Filter = "Word Files (*.docx)|*.docx|All Files (*.*)|*.*",
                Title = "选择 Word 模板"
            };

            if (dialog.ShowDialog() == true && DataContext is SettingsViewModel vm)
            {
                vm.WordTemplatePath = dialog.FileName;
            }
        }

        private void CancelButton_Click(object sender, RoutedEventArgs e)
        {
            // If this is inside a dialog, close it
            var window = Window.GetWindow(this);
            window?.Close();
        }
    }

    /// <summary>
    /// Helper class to switch between themes at runtime.
    /// </summary>
    public static class ThemeHelper
    {
        private static readonly string LightThemeUri = "pack://application:,,,/CadAttrExtractor;component/Views/Themes/LightTheme.xaml";
        private static readonly string DarkThemeUri = "pack://application:,,,/CadAttrExtractor;component/Views/Themes/DarkTheme.xaml";

        public static void ApplyTheme(string themeName)
        {
            try
            {
                var app = Application.Current;
                if (app == null) return;

                // Remove existing theme dictionaries
                var toRemove = new System.Collections.Generic.List<ResourceDictionary>();
                foreach (var dict in app.Resources.MergedDictionaries)
                {
                    if (dict.Source != null &&
                        (dict.Source.OriginalString.Contains("LightTheme") ||
                         dict.Source.OriginalString.Contains("DarkTheme")))
                    {
                        toRemove.Add(dict);
                    }
                }

                foreach (var dict in toRemove)
                {
                    app.Resources.MergedDictionaries.Remove(dict);
                }

                // Add the selected theme
                var themeUri = themeName == "DarkTheme" ? DarkThemeUri : LightThemeUri;
                var newDict = new ResourceDictionary { Source = new Uri(themeUri) };
                app.Resources.MergedDictionaries.Add(newDict);

                // Save preference
                SettingsService.Instance.UpdateSettings(s =>
                {
                    s.UI.Theme = themeName;
                });

                CadAttrExtractorApp.WriteLine($"[Theme] Switched to {themeName}");
            }
            catch (System.Exception ex)
            {
                CadAttrExtractorApp.WriteLine($"[Theme] Failed to apply {themeName}: {ex.Message}");
            }
        }
    }
}
