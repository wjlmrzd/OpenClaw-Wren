using System;
using System.Collections.Generic;

namespace CadAttrExtractor
{
    /// <summary>
    /// Service for sorting extracted items by various criteria.
    /// </summary>
    public static class SortService
    {
        /// <summary>
        /// Sorts the items using the specified mode and tolerance.
        /// </summary>
        /// <param name="items">The items to sort (modified in place).</param>
        /// <param name="mode">The sort mode to use.</param>
        /// <param name="tolerance">Coordinate tolerance for grouping items on same line.</param>
        public static void Sort(List<ExtractedItem> items, SortMode mode, double tolerance = 1.0)
        {
            if (items == null || items.Count <= 1) return;

            switch (mode)
            {
                case SortMode.TopToBottomLeftToRight:
                    SortTopToBottomLeftToRight(items, tolerance);
                    break;

                case SortMode.LeftToRightTopToBottom:
                    SortLeftToRightTopToBottom(items, tolerance);
                    break;

                case SortMode.LeftToRightBottomToTop:
                    SortLeftToRightBottomToTop(items, tolerance);
                    break;

                case SortMode.SelectionOrder:
                    SortBySelectionOrder(items);
                    break;

                default:
                    SortTopToBottomLeftToRight(items, tolerance);
                    break;
            }

            // Update selection orders after sorting
            for (int i = 0; i < items.Count; i++)
            {
                items[i].SelectionOrder = i;
            }
        }

        /// <summary>
        /// Sorts by Y descending (top to bottom), then X ascending (left to right).
        /// </summary>
        private static void SortTopToBottomLeftToRight(List<ExtractedItem> items, double tolerance)
        {
            items.Sort((a, b) =>
            {
                // Compare Y coordinates (descending - top first)
                var dy = b.PositionY - a.PositionY;
                if (Math.Abs(dy) > tolerance)
                {
                    return dy > 0 ? 1 : -1;
                }

                // If on same horizontal band, compare X (ascending - left first)
                return a.PositionX.CompareTo(b.PositionX);
            });
        }

        /// <summary>
        /// Sorts by X ascending (left to right), then Y descending (top to bottom).
        /// </summary>
        private static void SortLeftToRightTopToBottom(List<ExtractedItem> items, double tolerance)
        {
            items.Sort((a, b) =>
            {
                // Compare X coordinates (ascending - left first)
                var dx = a.PositionX - b.PositionX;
                if (Math.Abs(dx) > tolerance)
                {
                    return dx > 0 ? 1 : -1;
                }

                // If on same vertical band, compare Y (descending - top first)
                return b.PositionY.CompareTo(a.PositionY);
            });
        }

        /// <summary>
        /// Sorts by X ascending (left to right), then Y ascending (bottom to top).
        /// </summary>
        private static void SortLeftToRightBottomToTop(List<ExtractedItem> items, double tolerance)
        {
            items.Sort((a, b) =>
            {
                // Compare X coordinates (ascending - left first)
                var dx = a.PositionX - b.PositionX;
                if (Math.Abs(dx) > tolerance)
                {
                    return dx > 0 ? 1 : -1;
                }

                // If on same vertical band, compare Y (ascending - bottom first)
                return a.PositionY.CompareTo(b.PositionY);
            });
        }

        /// <summary>
        /// Sorts by original selection order.
        /// </summary>
        private static void SortBySelectionOrder(List<ExtractedItem> items)
        {
            items.Sort((a, b) => a.SelectionOrder.CompareTo(b.SelectionOrder));
        }

        /// <summary>
        /// Calculates the bounding box of all items.
        /// </summary>
        /// <param name="items">The items to measure.</param>
        /// <returns>A tuple of (minX, minY, maxX, maxY).</returns>
        public static (double MinX, double MinY, double MaxX, double MaxY) CalculateBounds(
            List<ExtractedItem> items)
        {
            if (items == null || items.Count == 0)
            {
                return (0, 0, 0, 0);
            }

            var minX = double.MaxValue;
            var minY = double.MaxValue;
            var maxX = double.MinValue;
            var maxY = double.MinValue;

            foreach (var item in items)
            {
                minX = Math.Min(minX, item.PositionX);
                minY = Math.Min(minY, item.PositionY);
                maxX = Math.Max(maxX, item.PositionX);
                maxY = Math.Max(maxY, item.PositionY);
            }

            return (minX, minY, maxX, maxY);
        }

        /// <summary>
        /// Calculates the center point of all items.
        /// </summary>
        public static (double X, double Y) CalculateCenter(List<ExtractedItem> items)
        {
            var bounds = CalculateBounds(items);
            return ((bounds.MinX + bounds.MaxX) / 2, (bounds.MinY + bounds.MaxY) / 2);
        }

        /// <summary>
        /// Removes duplicate items based on position (within tolerance).
        /// </summary>
        public static List<ExtractedItem> RemoveDuplicates(List<ExtractedItem> items, double tolerance = 0.1)
        {
            if (items == null || items.Count <= 1) return items;

            var result = new List<ExtractedItem>();
            var addedPositions = new HashSet<(double, double)>();

            foreach (var item in items)
            {
                var key = (Math.Round(item.PositionX / tolerance), Math.Round(item.PositionY / tolerance));
                if (!addedPositions.Contains(key))
                {
                    result.Add(item);
                    addedPositions.Add(key);
                }
            }

            return result;
        }
    }
}
