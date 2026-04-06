using Autodesk.AutoCAD.Geometry;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Windows.Input;
using CadAttrExtractor.Models;

namespace CadAttrExtractor.ViewModels
{
    /// <summary>
    /// Main view model for the plugin UI.
    /// </summary>
    public class MainViewModel : INotifyPropertyChanged
    {
        private ObservableCollection<ExtractedItemViewModel> _items = new();
        private ObservableCollection<GroupedItemViewModel> _groupedItems = new();
        private SortMode _selectedSortMode = SortMode.TopToBottomLeftToRight;
        private bool _isExtracting;
        private bool _isExporting;
        private double _progressValue;
        private string _statusMessage = "就绪";
        private string _blockNamePattern = "*";
        private string _attributeTag = "";
        private string _layerName = "";
        private Point3d _insertionPoint = Point3d.Origin;
        private bool _pointSelected;

        // Table settings
        private double _rowHeight = 8.0;
        private double _columnWidth = 50.0;
        private double _textHeight = 3.0;
        private string _tableHeaderText = "图纸目录";
        private ObservableCollection<string> _textStyles = new();
        private string _selectedTextStyle = "Standard";

        // Export tag mappings
        private string _titleTag = "图名";
        private string _indexTag = "图号";
        private string _versionTag = "版本";
        private string _dateTag = "日期";

        // Export options
        private string _excelTemplatePath = "";
        private string _wordTemplatePath = "";
        private bool _exportCSV;
        private string _csvEncoding = "UTF-8";
        private string _csvSeparator = ",";
        private bool _csvIncludeHeader = true;
        private bool _useTemplateFormatting = true;
        private bool _showProgress = true;

        // Table options
        private bool _autoPagination = true;
        private int _rowsPerPage = 30;
        private double _indexColumnWidth = 5.0;

        public event PropertyChangedEventHandler PropertyChanged;

        // Collections
        public ObservableCollection<ExtractedItemViewModel> Items
        {
            get => _items;
            set { _items = value; OnPropertyChanged(); }
        }

        public ObservableCollection<GroupedItemViewModel> GroupedItems
        {
            get => _groupedItems;
            set { _groupedItems = value; OnPropertyChanged(); }
        }

        // Sort Mode
        public SortMode SelectedSortMode
        {
            get => _selectedSortMode;
            set
            {
                _selectedSortMode = value;
                OnPropertyChanged();
                OnSortModeChanged();
            }
        }

        public Array SortModes => Enum.GetValues(typeof(SortMode));

        // Settings ViewModel for Settings tab
        private SettingsViewModel _settingsViewModel;
        public SettingsViewModel Settings
        {
            get
            {
                if (_settingsViewModel == null)
                {
                    _settingsViewModel = new SettingsViewModel();
                }
                return _settingsViewModel;
            }
        }

        // Status
        public bool IsExtracting
        {
            get => _isExtracting;
            set { _isExtracting = value; OnPropertyChanged(); }
        }

        public bool IsExporting
        {
            get => _isExporting;
            set { _isExporting = value; OnPropertyChanged(); }
        }

        public double ProgressValue
        {
            get => _progressValue;
            set { _progressValue = value; OnPropertyChanged(); }
        }

        public string StatusMessage
        {
            get => _statusMessage;
            set { _statusMessage = value; OnPropertyChanged(); }
        }

        // Filter inputs
        public string BlockNamePattern
        {
            get => _blockNamePattern;
            set { _blockNamePattern = value; OnPropertyChanged(); }
        }

        public string AttributeTag
        {
            get => _attributeTag;
            set { _attributeTag = value; OnPropertyChanged(); }
        }

        public string LayerName
        {
            get => _layerName;
            set { _layerName = value; OnPropertyChanged(); }
        }

        // Include anonymous blocks
        public bool IncludeAnonymousBlocks
        {
            get => SettingsService.Instance.Current.Extraction.IncludeAnonymousBlocks;
            set
            {
                SettingsService.Instance.Current.Extraction.IncludeAnonymousBlocks = value;
                OnPropertyChanged();
            }
        }

        public bool ShowProgress
        {
            get => _showProgress;
            set { _showProgress = value; OnPropertyChanged(); }
        }

        public bool ConfirmBeforeExtract
        {
            get => SettingsService.Instance.Current.UI.ConfirmBeforeExtract;
            set
            {
                SettingsService.Instance.UpdateSettings(s => s.UI.ConfirmBeforeExtract = value);
                OnPropertyChanged();
            }
        }

        // Table settings
        public double RowHeight
        {
            get => _rowHeight;
            set { _rowHeight = value; OnPropertyChanged(); }
        }

        public double ColumnWidth
        {
            get => _columnWidth;
            set { _columnWidth = value; OnPropertyChanged(); }
        }

        public double TextHeight
        {
            get => _textHeight;
            set { _textHeight = value; OnPropertyChanged(); }
        }

        public string TableHeaderText
        {
            get => _tableHeaderText;
            set { _tableHeaderText = value; OnPropertyChanged(); }
        }

        public ObservableCollection<string> TextStyles
        {
            get => _textStyles;
            set { _textStyles = value; OnPropertyChanged(); }
        }

        public string SelectedTextStyle
        {
            get => _selectedTextStyle;
            set { _selectedTextStyle = value; OnPropertyChanged(); }
        }

        // Export tag mappings
        public string TitleTag
        {
            get => _titleTag;
            set { _titleTag = value; OnPropertyChanged(); }
        }

        public string IndexTag
        {
            get => _indexTag;
            set { _indexTag = value; OnPropertyChanged(); }
        }

        public string VersionTag
        {
            get => _versionTag;
            set { _versionTag = value; OnPropertyChanged(); }
        }

        public string DateTag
        {
            get => _dateTag;
            set { _dateTag = value; OnPropertyChanged(); }
        }

        // Export options
        public string ExcelTemplatePath
        {
            get => _excelTemplatePath;
            set { _excelTemplatePath = value; OnPropertyChanged(); }
        }

        public string WordTemplatePath
        {
            get => _wordTemplatePath;
            set { _wordTemplatePath = value; OnPropertyChanged(); }
        }

        public bool ExportCSV
        {
            get => _exportCSV;
            set { _exportCSV = value; OnPropertyChanged(); }
        }

        public string CSVEncoding
        {
            get => _csvEncoding;
            set { _csvEncoding = value; OnPropertyChanged(); }
        }

        public string CSVSeparator
        {
            get => _csvSeparator;
            set { _csvSeparator = value; OnPropertyChanged(); }
        }

        public bool CSVIncludeHeader
        {
            get => _csvIncludeHeader;
            set { _csvIncludeHeader = value; OnPropertyChanged(); }
        }

        public bool UseTemplateFormatting
        {
            get => _useTemplateFormatting;
            set { _useTemplateFormatting = value; OnPropertyChanged(); }
        }

        // Table options
        public bool AutoPagination
        {
            get => _autoPagination;
            set { _autoPagination = value; OnPropertyChanged(); }
        }

        public int RowsPerPage
        {
            get => _rowsPerPage;
            set { _rowsPerPage = value; OnPropertyChanged(); }
        }

        public double IndexColumnWidth
        {
            get => _indexColumnWidth;
            set { _indexColumnWidth = value; OnPropertyChanged(); }
        }

        public int EstimatedPages => AutoPagination && RowsPerPage > 0
            ? (int)Math.Ceiling((double)Items.Count / RowsPerPage)
            : 1;

        // Insertion point
        public Point3d InsertionPoint
        {
            get => _insertionPoint;
            set { _insertionPoint = value; OnPropertyChanged(); }
        }

        public bool PointSelected
        {
            get => _pointSelected;
            set { _pointSelected = value; OnPropertyChanged(); }
        }

        public string InsertionPointText => PointSelected
            ? $"({InsertionPoint.X:F2}, {InsertionPoint.Y:F2})"
            : "未设�?;

        // Commands
        public ICommand ExtractCommand { get; }
        public ICommand SortCommand { get; }
        public ICommand GenerateTableCommand { get; }
        public ICommand ExportExcelCommand { get; }
        public ICommand ExportWordCommand { get; }
        public ICommand ExportCSVCommand { get; }
        public ICommand ClearCommand { get; }
        public ICommand PickPointCommand { get; }
        public ICommand RemoveItemCommand { get; }
        public ICommand MoveUpCommand { get; }
        public ICommand MoveDownCommand { get; }
        public ICommand ClearExcelTemplateCommand { get; }
        public ICommand ClearWordTemplateCommand { get; }

        public MainViewModel()
        {
            // Initialize commands
            ExtractCommand = new RelayCommand(ExecuteExtract, CanExecuteExtract);
            SortCommand = new RelayCommand(ExecuteSort, CanExecuteSort);
            GenerateTableCommand = new RelayCommand(ExecuteGenerateTable, CanExecuteGenerateTable);
            ExportExcelCommand = new RelayCommand(ExecuteExportExcel, CanExecuteExport);
            ExportWordCommand = new RelayCommand(ExecuteExportWord, CanExecuteExport);
            ExportCSVCommand = new RelayCommand(ExecuteExportCSV, CanExecuteExport);
            ClearCommand = new RelayCommand(ExecuteClear, CanExecuteClear);
            PickPointCommand = new RelayCommand(ExecutePickPoint);
            RemoveItemCommand = new RelayCommand(ExecuteRemoveItem);
            MoveUpCommand = new RelayCommand(ExecuteMoveUp);
            MoveDownCommand = new RelayCommand(ExecuteMoveDown);
            ClearExcelTemplateCommand = new RelayCommand(ExecuteClearExcelTemplate);
            ClearWordTemplateCommand = new RelayCommand(ExecuteClearWordTemplate);

            // Load saved settings
            _selectedSortMode = SettingsService.Instance.Current.UI.LastSortMode;
            _excelTemplatePath = SettingsService.Instance.Current.Export.ExcelTemplatePath ?? "";
            _wordTemplatePath = SettingsService.Instance.Current.Export.WordTemplatePath ?? "";
            _showProgress = SettingsService.Instance.Current.Extraction.ShowProgress;
            _autoPagination = SettingsService.Instance.Current.Table.AutoPagination;
            _rowsPerPage = SettingsService.Instance.Current.Table.RowsPerPage;

            CadAttrExtractorApp.WriteLine("[MainViewModel] Initialized");
        }

        /// <summary>
        /// Loads items into the view model.
        /// </summary>
        public void LoadItems(List<ExtractedItem> items)
        {
            Items.Clear();
            foreach (var item in items)
            {
                Items.Add(new ExtractedItemViewModel(item));
            }

            StatusMessage = $"已加载 {Items.Count} 项";
            OnPropertyChanged(nameof(Items));
            OnPropertyChanged(nameof(HasItems));

            CadAttrExtractorApp.WriteLine($"[MainViewModel] Loaded {items.Count} items");
        }

        public bool HasItems => Items.Count > 0;

        private bool CanExecuteExtract() => !IsExtracting;
        private void ExecuteExtract()
        {
            IsExtracting = true;
            StatusMessage = "正在提取...";
            Commands.ExtractAttributes();
            IsExtracting = false;
            StatusMessage = $"提取完成: {Items.Count} 项";
        }

        private bool CanExecuteSort() => HasItems;
        private void ExecuteSort()
        {
            var items = Items.Select(vm => vm.Model).ToList();
            SortService.Sort(items, SelectedSortMode, SettingsService.Instance.Current.Extraction.Tolerance);

            for (int i = 0; i < items.Count; i++)
            {
                items[i].SelectionOrder = i;
            }

            // Re-sort the observable collection
            var sortedList = items.Select(m => new ExtractedItemViewModel(m)).ToList();
            Items.Clear();
            foreach (var item in sortedList)
            {
                Items.Add(item);
            }

            StatusMessage = $"已按 {SelectedSortMode.GetDisplayName()} 排序";
            OnPropertyChanged(nameof(Items));
        }

        private void OnSortModeChanged()
        {
            if (SettingsService.Instance.Current.UI.RememberLastSortMode)
            {
                SettingsService.Instance.UpdateSettings(s => s.UI.LastSortMode = SelectedSortMode);
            }
        }

        private bool CanExecuteGenerateTable() => HasItems && PointSelected;
        private void ExecuteGenerateTable()
        {
            var items = Items.Select(vm => vm.Model).ToList();
            var settings = SettingsService.Instance.Current.Table;

            Commands.GenerateTable();
            StatusMessage = "表格已生成";
        }

        private bool CanExecuteExport() => HasItems && !IsExporting;
        private void ExecuteExportExcel()
        {
            IsExporting = true;
            StatusMessage = "正在导出 Excel...";
            Commands.ExportToExcel();
            IsExporting = false;
            StatusMessage = "Excel 导出完成";
        }

        private void ExecuteExportWord()
        {
            IsExporting = true;
            StatusMessage = "正在导出 Word...";
            Commands.ExportToWord();
            IsExporting = false;
            StatusMessage = "Word 导出完成";
        }

        private bool CanExecuteClear() => HasItems;
        private void ExecuteClear()
        {
            Items.Clear();
            GroupedItems.Clear();
            StatusMessage = "已清空";
            OnPropertyChanged(nameof(HasItems));
        }

        private void ExecutePickPoint()
        {
            Commands.PickTablePoint();
            OnPropertyChanged(nameof(InsertionPointText));
        }

        private void ExecuteRemoveItem(object parameter)
        {
            if (parameter is ExtractedItemViewModel item)
            {
                Items.Remove(item);
                StatusMessage = $"已删除 {item.BlockName}";
                OnPropertyChanged(nameof(HasItems));
            }
        }

        private void ExecuteMoveUp(object parameter)
        {
            if (parameter is ExtractedItemViewModel item)
            {
                var index = Items.IndexOf(item);
                if (index > 0)
                {
                    Items.Move(index, index - 1);
                }
            }
        }

        private void ExecuteMoveDown(object parameter)
        {
            if (parameter is ExtractedItemViewModel item)
            {
                var index = Items.IndexOf(item);
                if (index < Items.Count - 1)
                {
                    Items.Move(index, index + 1);
                }
            }
        }

        private void ExecuteExportCSV()
        {
            IsExporting = true;
            StatusMessage = "正在导出 CSV...";
            Commands.ExportToExcel(); // Uses same pattern, could add CSV-specific
            IsExporting = false;
            StatusMessage = "CSV 导出完成";
        }

        private void ExecuteClearExcelTemplate()
        {
            ExcelTemplatePath = "";
            SettingsService.Instance.UpdateSettings(s => s.Export.ExcelTemplatePath = "");
        }

        private void ExecuteClearWordTemplate()
        {
            WordTemplatePath = "";
            SettingsService.Instance.UpdateSettings(s => s.Export.WordTemplatePath = "");
        }

        public void SetInsertionPoint(Point3d point)
        {
            InsertionPoint = point;
            PointSelected = true;
            OnPropertyChanged(nameof(InsertionPointText));
        }

        protected virtual void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }

    /// <summary>
    /// Simple relay command implementation.
    /// </summary>
    public class RelayCommand : ICommand
    {
        private readonly Action _execute;
        private readonly Func<bool> _canExecute;

        public RelayCommand(Action execute, Func<bool> canExecute = null)
        {
            _execute = execute ?? throw new ArgumentNullException(nameof(execute));
            _canExecute = canExecute;
        }

        public RelayCommand(Action<object> execute, Func<object, bool> canExecute = null)
        {
            _execute = () => execute(null);
            _canExecute = canExecute == null ? null : _ => canExecute(null);
        }

        public event EventHandler CanExecuteChanged
        {
            add => CommandManager.RequerySuggested += value;
            remove => CommandManager.RequerySuggested -= value;
        }

        public bool CanExecute(object parameter) => _canExecute?.Invoke() ?? true;
        public void Execute(object parameter) => _execute();
    }
}
