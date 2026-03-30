using System;
using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace CadAttrExtractor.ViewModels
{
    /// <summary>
    /// View model wrapper for an ExtractedItem.
    /// </summary>
    public class ExtractedItemViewModel : INotifyPropertyChanged
    {
        private readonly ExtractedItem _model;
        private bool _isSelected;
        private bool _isExpanded;

        public event PropertyChangedEventHandler PropertyChanged;

        /// <summary>
        /// Gets the underlying model.
        /// </summary>
        public ExtractedItem Model => _model;

        /// <summary>
        /// Gets the block name.
        /// </summary>
        public string BlockName => _model.BlockName;

        /// <summary>
        /// Gets the drawing title.
        /// </summary>
        public string DrawingTitle => _model.DrawingTitle ?? "-";

        /// <summary>
        /// Gets the drawing index.
        /// </summary>
        public string DrawingIndex => _model.DisplayIndex;

        /// <summary>
        /// Gets the block handle.
        /// </summary>
        public string BlockHandle => _model.BlockHandle;

        /// <summary>
        /// Gets the X position.
        /// </summary>
        public double PositionX => _model.PositionX;

        /// <summary>
        /// Gets the Y position.
        /// </summary>
        public double PositionY => _model.PositionY;

        /// <summary>
        /// Gets the position as formatted string.
        /// </summary>
        public string PositionText => $"({PositionX:F2}, {PositionY:F2})";

        /// <summary>
        /// Gets the selection order.
        /// </summary>
        public int SelectionOrder => _model.SelectionOrder;

        /// <summary>
        /// Gets the extracted timestamp.
        /// </summary>
        public DateTime ExtractedAt => _model.ExtractedAt;

        /// <summary>
        /// Gets the display index (1-based).
        /// </summary>
        public string DisplayIndex => (_model.SelectionOrder + 1).ToString();

        /// <summary>
        /// Gets all attributes as a formatted string.
        /// </summary>
        public string AttributesText
        {
            get
            {
                if (_model.Attributes == null || _model.Attributes.Count == 0)
                    return "-";

                var lines = new System.Collections.Generic.List<string>();
                foreach (var kvp in _model.Attributes)
                {
                    lines.Add($"{kvp.Key}: {kvp.Value}");
                }
                return string.Join("\n", lines);
            }
        }

        public bool IsSelected
        {
            get => _isSelected;
            set
            {
                _isSelected = value;
                _model.IsSelected = value;
                OnPropertyChanged();
            }
        }

        public bool IsExpanded
        {
            get => _isExpanded;
            set
            {
                _isExpanded = value;
                OnPropertyChanged();
            }
        }

        public ExtractedItemViewModel(ExtractedItem model)
        {
            _model = model ?? throw new ArgumentNullException(nameof(model));
        }

        protected virtual void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
