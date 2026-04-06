using Newtonsoft.Json;
using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;

namespace CadAttrExtractor
{
    /// <summary>
    /// Singleton service for managing application settings persistence.
    /// </summary>
    public sealed class SettingsService
    {
        private static readonly Lazy<SettingsService> _instance = new(() => new SettingsService());
        private AppSettings _current;
        private readonly string _settingsPath;
        private readonly object _lock = new();
        private CancellationTokenSource _saveDebounceToken;
        private const int SaveDebounceMs = 1000;

        /// <summary>
        /// Gets the singleton instance.
        /// </summary>
        public static SettingsService Instance => _instance.Value;

        /// <summary>
        /// Gets the current settings.
        /// </summary>
        public AppSettings Current => _current;

        private SettingsService()
        {
            _current = AppSettings.CreateDefault();

            _settingsPath = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                "Autodesk", "Autodesk Desktop App", "Plugins", "CadAttrExtractor", "settings.json");

            CadAttrExtractorApp.WriteLine($"[Settings] Path: {_settingsPath}");
        }

        /// <summary>
        /// Loads settings from disk.
        /// </summary>
        public void Load()
        {
            lock (_lock)
            {
                try
                {
                    if (File.Exists(_settingsPath))
                    {
                        var json = File.ReadAllText(_settingsPath);
                        var settings = JsonConvert.DeserializeObject<AppSettings>(json);

                        if (settings != null)
                        {
                            _current = settings;
                            CadAttrExtractorApp.WriteLine($"[Settings] Loaded from {_settingsPath}");
                        }
                        else
                        {
                            _current = AppSettings.CreateDefault();
                            CadAttrExtractorApp.WriteLine("[Settings] Loaded defaults (deserialization failed)");
                        }
                    }
                    else
                    {
                        _current = AppSettings.CreateDefault();
                        Save(); // Create default settings file
                        CadAttrExtractorApp.WriteLine("[Settings] Created default settings");
                    }
                }
                catch (System.Exception ex)
                {
                    CadAttrExtractorApp.WriteLine($"[Settings] Load error: {ex.Message}");
                    _current = AppSettings.CreateDefault();
                }
            }
        }

        /// <summary>
        /// Saves settings to disk.
        /// </summary>
        public void Save()
        {
            lock (_lock)
            {
                try
                {
                    var directory = Path.GetDirectoryName(_settingsPath);
                    if (!string.IsNullOrEmpty(directory))
                    {
                        Directory.CreateDirectory(directory);
                    }

                    _current.LastModified = DateTime.Now;

                    var json = JsonConvert.SerializeObject(_current, Formatting.Indented);
                    File.WriteAllText(_settingsPath, json);

                    CadAttrExtractorApp.WriteLine($"[Settings] Saved to {_settingsPath}");
                }
                catch (System.Exception ex)
                {
                    CadAttrExtractorApp.WriteLine($"[Settings] Save error: {ex.Message}");
                }
            }
        }

        /// <summary>
        /// Saves settings with debouncing to avoid excessive disk writes.
        /// </summary>
        public void SaveDebounced()
        {
            lock (_lock)
            {
                _saveDebounceToken?.Cancel();
                _saveDebounceToken = new CancellationTokenSource();
            }

            Task.Delay(SaveDebounceMs, _saveDebounceToken.Token)
                .ContinueWith(t =>
                {
                    if (!t.IsCanceled)
                    {
                        Save();
                    }
                }, TaskScheduler.Default);
        }

        /// <summary>
        /// Updates a specific settings section.
        /// </summary>
        public void UpdateSettings(Action<AppSettings> updateAction)
        {
            lock (_lock)
            {
                updateAction(_current);
                _current.LastModified = DateTime.Now;
            }
            SaveDebounced();
        }

        /// <summary>
        /// Resets all settings to defaults.
        /// </summary>
        public void Reset()
        {
            lock (_lock)
            {
                _current = AppSettings.CreateDefault();
            }
            Save();
            CadAttrExtractorApp.WriteLine("[Settings] Reset to defaults");
        }

        /// <summary>
        /// Resets all settings to defaults (alias for Reset).
        /// </summary>
        public void ResetToDefault()
        {
            Reset();
        }

        /// <summary>
        /// Gets the settings file path.
        /// </summary>
        public string GetSettingsPath() => _settingsPath;

        /// <summary>
        /// Opens the settings folder in Explorer.
        /// </summary>
        public void OpenSettingsFolder()
        {
            try
            {
                var folder = Path.GetDirectoryName(_settingsPath);
                if (Directory.Exists(folder))
                {
                    System.Diagnostics.Process.Start("explorer.exe", folder);
                }
            }
            catch (System.Exception ex)
            {
                CadAttrExtractorApp.WriteLine($"[Settings] Open folder error: {ex.Message}");
            }
        }
    }
}
