using Autodesk.AutoCAD.ApplicationServices;
using System.Windows;
using CadAttrExtractor.ViewModels;

namespace CadAttrExtractor.Views
{
    /// <summary>
    /// Main window for the PaletteSet container.
    /// Hosts 5 tabs: Extract, Preview, Table, Export, Settings.
    /// </summary>
    public partial class MainWindow : Window
    {
        private static MainWindow _instance;
        private readonly MainViewModel _viewModel;

        /// <summary>
        /// Gets the singleton instance of MainWindow.
        /// </summary>
        public static MainWindow Instance => _instance;

        /// <summary>
        /// Gets the DataContext as MainViewModel.
        /// </summary>
        public MainViewModel ViewModel => _viewModel;

        public MainWindow()
        {
            InitializeComponent();

            _instance = this;
            _viewModel = new MainViewModel();
            DataContext = _viewModel;

            // Apply saved theme
            ApplySavedTheme();

            CadAttrExtractorApp.WriteLine("[MainWindow] Initialized");
        }

        private void ApplySavedTheme()
        {
            try
            {
                var theme = SettingsService.Instance.Current.UI.Theme;
                if (theme == "DarkTheme")
                {
                    ThemeToggle.IsChecked = true;
                    ThemeHelper.ApplyTheme("DarkTheme");
                }
                else
                {
                    ThemeToggle.IsChecked = false;
                    ThemeHelper.ApplyTheme("LightTheme");
                }
            }
            catch (System.Exception ex)
            {
                CadAttrExtractorApp.WriteLine($"[MainWindow] Theme init error: {ex.Message}");
            }
        }

        private void ThemeToggle_Click(object sender, RoutedEventArgs e)
        {
            if (ThemeToggle.IsChecked == true)
            {
                ThemeHelper.ApplyTheme("DarkTheme");
            }
            else
            {
                ThemeHelper.ApplyTheme("LightTheme");
            }
        }

        private void SettingsButton_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                // Switch to settings tab
                if (MainTabControl.Items.Count > 4)
                {
                    MainTabControl.SelectedIndex = 4; // Settings tab
                }
            }
            catch (System.Exception ex)
            {
                CadAttrExtractorApp.WriteLine($"[MainWindow] Settings nav error: {ex.Message}");
            }
        }

        private void AboutButton_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                var aboutDialog = new AboutDialog();
                aboutDialog.Owner = this;
                aboutDialog.ShowDialog();
            }
            catch (System.Exception ex)
            {
                CadAttrExtractorApp.WriteLine($"[MainWindow] About dialog error: {ex.Message}");
            }
        }

        private void CloseButton_Click(object sender, RoutedEventArgs e)
        {
            // Hide the palette instead of closing the window
            this.Hide();
        }

        protected override void OnClosing(System.ComponentModel.CancelEventArgs e)
        {
            // Prevent actual closing - just hide
            e.Cancel = true;
            this.Hide();
        }
    }
}
