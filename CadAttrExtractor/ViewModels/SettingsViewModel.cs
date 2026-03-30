using System;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows.Input;

namespace CadAttrExtractor.ViewModels
{
    /// <summary>
    /// View model for the settings dialog.
    /// </summary>
    public class SettingsViewModel : INotifyPropertyChanged
    {
        private AppSettings _settings;
        private bool _hasChanges;

        public event PropertyChangedEventHandler PropertyChanged;

        // Extraction Settings
        public double ExtractionTolerance
        {
            get => _settings.Extraction.Tolerance;
            set
            {
                _settings.Extraction.Tolerance = value;
                HasChanges = true;
                OnPropertyChanged();
            }
        }

        public bool IncludeAnonymousBlocks
        {
            get => _settings.Extraction.IncludeAnonymousBlocks;
            set
            {
                _settings.Extraction.IncludeAnonymousBlocks = value;
                HasChanges = true;
                OnPropertyChanged();
            }
        }

        public string TitleRegexPatterns
        {
            get => string.Join(Environment.NewLine, _settings.Extraction.TitleRegexPatterns);
            set
            {
                var lines = value.Split(new[] { Environment.NewLine }, StringSplitOptions.RemoveEmptyEntries);
                _settings.Extraction.TitleRegexPatterns.Clear();
                foreach (var line in lines)
                {
                    _settings.Extraction.TitleRegexPatterns.Add(line.Trim());
                }
                HasChanges = true;
                OnPropertyChanged();
            }
        }

        // Table Settings
        public double TableRowHeight
        {
            get => _settings.Table.RowHeight;
            set
            {
                _settings.Table.RowHeight = value;
                HasChanges = true;
                OnPropertyChanged();
            }
        }

        public double ColumnWidthA
        {
            get => _settings.Table.ColumnWidthA;
            set
            {
                _settings.Table.ColumnWidthA = value;
                HasChanges = true;
                OnPropertyChanged();
            }
        }

        public double ColumnWidthB
        {
            get => _settings.Table.ColumnWidthB;
            set
            {
                _settings.Table.ColumnWidthB = value;
                HasChanges = true;
                OnPropertyChanged();
            }
        }

        public double ColumnWidthC
        {
            get => _settings.Table.ColumnWidthC;
            set
            {
                _settings.Table.ColumnWidthC = value;
                HasChanges = true;
                OnPropertyChanged();
            }
        }

        public double ColumnWidthD
        {
            get => _settings.Table.ColumnWidthD;
            set
            {
                _settings.Table.ColumnWidthD = value;
                HasChanges = true;
                OnPropertyChanged();
            }
        }

        public double TextHeight
        {
            get => _settings.Table.TextHeight;
            set
            {
                _settings.Table.TextHeight = value;
                HasChanges = true;
                OnPropertyChanged();
            }
        }

        public string HeaderText
        {
            get => _settings.Table.HeaderText;
            set
            {
                _settings.Table.HeaderText = value;
                HasChanges = true;
                OnPropertyChanged();
            }
        }

        public bool AutoPagination
        {
            get => _settings.Table.AutoPagination;
            set
            {
                _settings.Table.AutoPagination = value;
                HasChanges = true;
                OnPropertyChanged();
            }
        }

        public int RowsPerPage
        {
            get => _settings.Table.RowsPerPage;
            set
            {
                _settings.Table.RowsPerPage = value;
                HasChanges = true;
                OnPropertyChanged();
            }
        }

        // Export Settings
        public string ExcelTemplatePath
        {
            get => _settings.Export.ExcelTemplatePath;
            set
            {
                _settings.Export.ExcelTemplatePath = value;
                HasChanges = true;
                OnPropertyChanged();
            }
        }

        public string WordTemplatePath
        {
            get => _settings.Export.WordTemplatePath;
            set
            {
                _settings.Export.WordTemplatePath = value;
                HasChanges = true;
                OnPropertyChanged();
            }
        }

        public string DrawingTitleTag
        {
            get => _settings.Export.DrawingTitleTag;
            set
            {
                _settings.Export.DrawingTitleTag = value;
                HasChanges = true;
                OnPropertyChanged();
            }
        }

        public string DrawingIndexTag
        {
            get => _settings.Export.DrawingIndexTag;
            set
            {
                _settings.Export.DrawingIndexTag = value;
                HasChanges = true;
                OnPropertyChanged();
            }
        }

        public string DrawingVersionTag
        {
            get => _settings.Export.DrawingVersionTag;
            set
            {
                _settings.Export.DrawingVersionTag = value;
                HasChanges = true;
                OnPropertyChanged();
            }
        }

        public string DrawingDateTag
        {
            get => _settings.Export.DrawingDateTag;
            set
            {
                _settings.Export.DrawingDateTag = value;
                HasChanges = true;
                OnPropertyChanged();
            }
        }

        // UI Settings
        public bool AutoShowPalette
        {
            get => _settings.UI.AutoShowPalette;
            set
            {
                _settings.UI.AutoShowPalette = value;
                HasChanges = true;
                OnPropertyChanged();
            }
        }

        public bool ConfirmBeforeExtract
        {
            get => _settings.UI.ConfirmBeforeExtract;
            set
            {
                _settings.UI.ConfirmBeforeExtract = value;
                HasChanges = true;
                OnPropertyChanged();
            }
        }

        public bool RememberLastSortMode
        {
            get => _settings.UI.RememberLastSortMode;
            set
            {
                _settings.UI.RememberLastSortMode = value;
                HasChanges = true;
                OnPropertyChanged();
            }
        }

        // State
        public bool HasChanges
        {
            get => _hasChanges;
            set
            {
                _hasChanges = value;
                OnPropertyChanged();
            }
        }

        public string SettingsVersion => _settings.Version;
        public DateTime LastModified => _settings.LastModified;

        // Commands
        public ICommand SaveCommand { get; }
        public ICommand ResetCommand { get; }
        public ICommand OpenConfigFolderCommand { get; }

        public SettingsViewModel()
        {
            _settings = SettingsService.Instance.Current.Clone();
            _hasChanges = false;

            SaveCommand = new RelayCommand(ExecuteSave);
            ResetCommand = new RelayCommand(ExecuteReset);
            OpenConfigFolderCommand = new RelayCommand(ExecuteOpenConfigFolder);
        }

        private void ExecuteSave()
        {
            SettingsService.Instance.UpdateSettings(s =>
            {
                s.Extraction = _settings.Extraction.Clone();
                s.Table = _settings.Table.Clone();
                s.Export = _settings.Export.Clone();
                s.UI = _settings.UI.Clone();
            });
            HasChanges = false;
            CadAttrExtractorApp.WriteLine("[SettingsViewModel] Settings saved");
        }

        private void ExecuteReset()
        {
            _settings = AppSettings.CreateDefault();
            HasChanges = true;
            RefreshAllProperties();
        }

        private void ExecuteOpenConfigFolder()
        {
            SettingsService.Instance.OpenSettingsFolder();
        }

        private void RefreshAllProperties()
        {
            OnPropertyChanged(nameof(ExtractionTolerance));
            OnPropertyChanged(nameof(IncludeAnonymousBlocks));
            OnPropertyChanged(nameof(TitleRegexPatterns));
            OnPropertyChanged(nameof(TableRowHeight));
            OnPropertyChanged(nameof(ColumnWidthA));
            OnPropertyChanged(nameof(ColumnWidthB));
            OnPropertyChanged(nameof(ColumnWidthC));
            OnPropertyChanged(nameof(ColumnWidthD));
            OnPropertyChanged(nameof(TextHeight));
            OnPropertyChanged(nameof(HeaderText));
            OnPropertyChanged(nameof(AutoPagination));
            OnPropertyChanged(nameof(RowsPerPage));
            OnPropertyChanged(nameof(ExcelTemplatePath));
            OnPropertyChanged(nameof(WordTemplatePath));
            OnPropertyChanged(nameof(DrawingTitleTag));
            OnPropertyChanged(nameof(DrawingIndexTag));
            OnPropertyChanged(nameof(DrawingVersionTag));
            OnPropertyChanged(nameof(DrawingDateTag));
            OnPropertyChanged(nameof(AutoShowPalette));
            OnPropertyChanged(nameof(ConfirmBeforeExtract));
            OnPropertyChanged(nameof(RememberLastSortMode));
        }

        protected virtual void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
