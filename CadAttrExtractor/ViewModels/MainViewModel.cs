using Autodesk.AutoCAD.Geometry;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Windows.Input;

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
        public ICommand ClearCommand { get; }
        public ICommand PickPointCommand { get; }
        public ICommand RemoveItemCommand { get; }
        public ICommand MoveUpCommand { get; }
        public ICommand MoveDownCommand { get; }

        public MainViewModel()
        {
            // Initialize commands
            ExtractCommand = new RelayCommand(ExecuteExtract, CanExecuteExtract);
            SortCommand = new RelayCommand(ExecuteSort, CanExecuteSort);
            GenerateTableCommand = new RelayCommand(ExecuteGenerateTable, CanExecuteGenerateTable);
            ExportExcelCommand = new RelayCommand(ExecuteExportExcel, CanExecuteExport);
            ExportWordCommand = new RelayCommand(ExecuteExportWord, CanExecuteExport);
            ClearCommand = new RelayCommand(ExecuteClear, CanExecuteClear);
            PickPointCommand = new RelayCommand(ExecutePickPoint);
            RemoveItemCommand = new RelayCommand(ExecuteRemoveItem);
            MoveUpCommand = new RelayCommand(ExecuteMoveUp);
            MoveDownCommand = new RelayCommand(ExecuteMoveDown);

            // Load saved sort mode
            _selectedSortMode = SettingsService.Instance.Current.UI.LastSortMode;

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

            StatusMessage = $"已加�?{Items.Count} �?;
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
            StatusMessage = $"提取完成: {Items.Count} �?;
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
            StatusMessage = "表格已生�?;
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
            StatusMessage = "已清�?;
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
                StatusMessage = $"已删�? {item.BlockName}";
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
