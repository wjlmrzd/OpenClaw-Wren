using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;

namespace CadAttrExtractor.Views
{
    /// <summary>
    /// Preview view with drag-drop reordering and sort mode selection.
    /// </summary>
    public partial class PreviewView : UserControl
    {
        private Point _dragStartPoint;
        private bool _isDragging;

        public PreviewView()
        {
            InitializeComponent();
        }

        private void ItemsDataGrid_PreviewMouseLeftButtonDown(object sender, MouseButtonEventArgs e)
        {
            _dragStartPoint = e.GetPosition(null);
            _isDragging = false;
        }

        private void ItemsDataGrid_PreviewMouseMove(object sender, MouseEventArgs e)
        {
            if (e.LeftButton != MouseButtonState.Pressed)
                return;

            var currentPosition = e.GetPosition(null);
            var diff = _dragStartPoint - currentPosition;

            // Only start drag if mouse moved more than a threshold
            if (System.Math.Abs(diff.X) > SystemParameters.MinimumHorizontalDragDistance ||
                System.Math.Abs(diff.Y) > SystemParameters.MinimumVerticalDragDistance)
            {
                if (_isDragging) return;
                _isDragging = true;

                var dataGrid = sender as DataGrid;
                if (dataGrid?.SelectedItem == null) return;

                var item = dataGrid.SelectedItem;
                if (item == null) return;

                try
                {
                    DragDrop.DoDragDrop(dataGrid, item, DragDropEffects.Move);
                }
                finally
                {
                    _isDragging = false;
                }
            }
        }

        private void ItemsDataGrid_PreviewMouseLeftButtonUp(object sender, MouseButtonEventArgs e)
        {
            _isDragging = false;
        }
    }
}