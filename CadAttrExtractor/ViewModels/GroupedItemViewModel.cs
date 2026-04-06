using System;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Runtime.CompilerServices;

namespace CadAttrExtractor.ViewModels
{
    /// <summary>
    /// View model wrapper for a GroupedItem.
    /// </summary>
    public class GroupedItemViewModel : INotifyPropertyChanged
    {
        private readonly GroupedItem _model;
        private bool _isExpanded;
        private bool _isSelected;

        public event PropertyChangedEventHandler PropertyChanged;

        /// <summary>
        /// Gets the underlying model.
        /// </summary>
        public GroupedItem Model => _model;

        /// <summary>
        /// Gets the group title.
        /// </summary>
        public string Title => _model.Title;

        /// <summary>
        /// Gets the group index.
        /// </summary>
        public string Index => _model.Index ?? "-";

        /// <summary>
        /// Gets the total count.
        /// </summary>
        public string Total => _model.Total ?? "-";

        /// <summary>
        /// Gets the member count.
        /// </summary>
        public int Count => _model.Count;

        /// <summary>
        /// Gets the display text.
        /// </summary>
        public string DisplayText => _model.DisplayText;

        /// <summary>
        /// Gets the position X.
        /// </summary>
        public double PositionX => _model.PositionX;

        /// <summary>
        /// Gets the position Y.
        /// </summary>
        public double PositionY => _model.PositionY;

        /// <summary>
        /// Gets the position text.
        /// </summary>
        public string PositionText => $"({PositionX:F2}, {PositionY:F2})";

        /// <summary>
        /// Gets the members as view models.
        /// </summary>
        public ObservableCollection<ExtractedItemViewModel> MemberViewModels { get; }

        public bool IsExpanded
        {
            get => _isExpanded;
            set
            {
                _isExpanded = value;
                OnPropertyChanged();
            }
        }

        public bool IsSelected
        {
            get => _isSelected;
            set
            {
                _isSelected = value;
                OnPropertyChanged();
            }
        }

        public GroupedItemViewModel(GroupedItem model)
        {
            _model = model ?? throw new ArgumentNullException(nameof(model));
            MemberViewModels = new ObservableCollection<ExtractedItemViewModel>(
                model.Members.Select(m => new ExtractedItemViewModel(m)));
        }

        protected virtual void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
