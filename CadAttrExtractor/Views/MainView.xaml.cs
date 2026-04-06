using System.Windows;
using System.Windows.Controls;
using CadAttrExtractor.ViewModels;

namespace CadAttrExtractor.Views
{
    /// <summary>
    /// Interaction logic for MainView.xaml
    /// </summary>
    public partial class MainView : UserControl
    {
        private static MainView _instance;
        private readonly MainViewModel _viewModel;

        /// <summary>
        /// Gets the singleton instance of MainView.
        /// </summary>
        public static MainView Instance => _instance;

        /// <summary>
        /// Gets the DataContext as MainViewModel.
        /// </summary>
        public MainViewModel ViewModel => _viewModel;

        public MainView()
        {
            InitializeComponent();

            _instance = this;
            _viewModel = new MainViewModel();
            DataContext = _viewModel;

            CadAttrExtractorApp.WriteLine("[MainView] Initialized");
        }

        private void SettingsButton_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                var settingsDialog = new SettingsDialog();
                settingsDialog.Owner = Application.Current.MainWindow;
                settingsDialog.ShowDialog();
            }
            catch (System.Exception ex)
            {
                CadAttrExtractorApp.WriteLine($"[MainView] Settings dialog error: {ex.Message}");
            }
        }

        private void AboutButton_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                var aboutDialog = new AboutDialog();
                aboutDialog.Owner = Application.Current.MainWindow;
                aboutDialog.ShowDialog();
            }
            catch (System.Exception ex)
            {
                CadAttrExtractorApp.WriteLine($"[MainView] About dialog error: {ex.Message}");
            }
        }
    }
}
