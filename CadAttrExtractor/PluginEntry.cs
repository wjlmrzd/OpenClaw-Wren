using Autodesk.AutoCAD.Runtime;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Windows;
using System;
using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Media;

namespace CadAttrExtractor
{
    /// <summary>
    /// Main plugin entry point implementing IExtensionApplication for AutoCAD.
    /// Handles initialization, palette creation, and resource loading.
    /// </summary>
    public class CadAttrExtractorApp : IExtensionApplication
    {
        private PaletteSet _paletteSet;
        private static readonly string PluginName = "CadAttrExtractor";
        private static readonly string PluginGuid = "E8A2C3D4-F5B1-4E7C-9D2A-6F8E1B4C3A2D";
        private static CadAttrExtractorApp _instance;

        /// <summary>
        /// Gets the singleton instance of this application.
        /// </summary>
        public static CadAttrExtractorApp Instance => _instance;

        /// <summary>
        /// Gets the main palette set for this plugin.
        /// </summary>
        public PaletteSet PaletteSet => _paletteSet;

        /// <summary>
        /// Called when AutoCAD loads the plugin. Initializes skin, registers commands,
        /// loads settings, and creates the main palette.
        /// </summary>
        public void Initialize()
        {
            _instance = this;

            try
            {
                InitializeSkin();
                RegisterCommands();
                SettingsService.Instance.Load();
                DocumentManager.DocumentLockModeChanged += OnLockModeChanged;
                CreatePaletteSet();

                if (SettingsService.Instance.Current.UI.AutoShowPalette)
                {
                    ShowPalette();
                }

                WriteLine($"[CadAttrExtractor] v1.0.0 initialized successfully");
            }
            catch (System.Exception ex)
            {
                WriteLine($"[CadAttrExtractor] Initialization error: {ex.Message}");
                WriteLine(ex.StackTrace);
            }
        }

        /// <summary>
        /// Called when AutoCAD unloads the plugin. Saves settings and cleans up resources.
        /// </summary>
        public void Terminate()
        {
            try
            {
                SettingsService.Instance.Save();
                _paletteSet?.Dispose();
                DocumentManager.DocumentLockModeChanged -= OnLockModeChanged;
                WriteLine("[CadAttrExtractor] Terminated successfully");
            }
            catch (System.Exception ex)
            {
                WriteLine($"[CadAttrExtractor] Termination error: {ex.Message}");
            }
        }

        /// <summary>
        /// Initializes the MasterSkin2 resources from bundle or loads default styles.
        /// </summary>
        private void InitializeSkin()
        {
            try
            {
                var bundlePath = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
                var skinPath = Path.Combine(bundlePath, "Skins", "MasterSkin2.xaml");

                if (File.Exists(skinPath))
                {
                    var skinDict = new ResourceDictionary { Source = new Uri(skinPath) };
                    Application.Current.Resources.MergedDictionaries.Add(skinDict);
                    WriteLine($"[Skin] Loaded MasterSkin2 from {skinPath}");
                }
                else
                {
                    WriteLine($"[Skin] MasterSkin2 not found at {skinPath}, using default styles");
                    LoadDefaultStyles();
                }
            }
            catch (System.Exception ex)
            {
                WriteLine($"[Skin] Failed to load MasterSkin2: {ex.Message}");
                LoadDefaultStyles();
            }
        }

        /// <summary>
        /// Loads fallback default styles when MasterSkin2 is unavailable.
        /// </summary>
        private void LoadDefaultStyles()
        {
            var styleDict = new ResourceDictionary();

            // Primary accent colors
            styleDict["PrimaryBrush"] = new SolidColorBrush(Color.FromRgb(0x1E, 0x88, 0xE5));
            styleDict["PrimaryDarkBrush"] = new SolidColorBrush(Color.FromRgb(0x15, 0x6D, 0xAA));
            styleDict["AccentBrush"] = new SolidColorBrush(Color.FromRgb(0xFF, 0x57, 0x22));

            // Background colors
            styleDict["PanelBackground"] = new SolidColorBrush(Color.FromRgb(0x2D, 0x2D, 0x30));
            styleDict["ControlBackground"] = new SolidColorBrush(Color.FromRgb(0x3E, 0x3E, 0x42));
            styleDict["InputBackground"] = new SolidColorBrush(Color.FromRgb(0x1E, 0x1E, 0x1E));

            // Text colors
            styleDict["PrimaryText"] = new SolidColorBrush(Colors.White);
            styleDict["SecondaryText"] = new SolidColorBrush(Color.FromRgb(0xB0, 0xB0, 0xB0));
            styleDict["DisabledText"] = new SolidColorBrush(Color.FromRgb(0x60, 0x60, 0x60));

            // Border colors
            styleDict["BorderBrush"] = new SolidColorBrush(Color.FromRgb(0x3F, 0x3F, 0x46));
            styleDict["FocusBorder"] = new SolidColorBrush(Color.FromRgb(0x1E, 0x88, 0xE5));

            // Typography
            styleDict["PrimaryFontFamily"] = new FontFamily("Segoe UI, Microsoft YaHei");
            styleDict["PrimaryFontSize"] = 12.0;
            styleDict["SmallFontSize"] = 10.0;
            styleDict["LargeFontSize"] = 14.0;
            styleDict["HeaderFontSize"] = 16.0;

            Application.Current.Resources.MergedDictionaries.Add(styleDict);
            WriteLine("[Skin] Default styles loaded");
        }

        /// <summary>
        /// Registers plugin commands with AutoCAD.
        /// </summary>
        private void RegisterCommands()
        {
            var methodCount = typeof(Commands).GetMethods(
                BindingFlags.Static | BindingFlags.Public |
                BindingFlags.DeclaredOnly).Length;
            WriteLine($"[Commands] Registered {methodCount} commands");
        }

        /// <summary>
        /// Creates and configures the main floating palette.
        /// </summary>
        private void CreatePaletteSet()
        {
            try
            {
                _paletteSet = new PaletteSet(
                    PluginGuid,
                    "图纸目录提取�?,
                    new Guid(PluginGuid));

                var mainView = new Views.MainView();
                _paletteSet.AddVisual("Main", mainView);

                _paletteSet.Size = new System.Drawing.Size(480, 620);
                _paletteSet.MinimumSize = new System.Drawing.Size(400, 500);
                _paletteSet.KeepFocus = false;
                _paletteSet.DockEnabled = DockSides.Left | DockSides.Right | DockSides.Bottom | DockSides.Top;

                WriteLine("[Palette] PaletteSet created successfully");
            }
            catch (System.Exception ex)
            {
                WriteLine($"[Palette] Failed to create PaletteSet: {ex.Message}");
            }
        }

        /// <summary>
        /// Shows the main floating palette.
        /// </summary>
        [CommandMethod("CTE", "_cte", CommandFlags.Session)]
        public void ShowPalette()
        {
            if (_paletteSet != null)
            {
                _paletteSet.Visible = true;
                WriteLine("[Palette] PaletteSet shown");
            }
        }

        /// <summary>
        /// Handles document lock mode changes.
        /// </summary>
        private void OnLockModeChanged(object sender, DocumentLockModeChangedEventArgs e)
        {
            WriteLine($"[Document] Lock mode changed: {e.CurrentMode}");
        }

        /// <summary>
        /// Writes a message to the plugin log file.
        /// </summary>
        /// <param name="message">The message to log.</param>
        public static void WriteLine(string message)
        {
            try
            {
                var logPath = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                    "Autodesk", "Autodesk Desktop App", "Plugins", PluginName, "logs");
                Directory.CreateDirectory(logPath);

                var logFile = Path.Combine(logPath, $"{DateTime.Now:yyyy-MM-dd}.log");
                var logEntry = $"[{DateTime.Now:HH:mm:ss.fff}] {message}{Environment.NewLine}";
                File.AppendAllText(logFile, logEntry);
            }
            catch
            {
                // Silently fail if logging fails
            }
        }
    }
}
