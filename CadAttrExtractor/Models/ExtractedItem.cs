using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using System;
using System.Collections.Generic;

namespace CadAttrExtractor
{
    /// <summary>
    /// Represents an extracted item from an AutoCAD block with attributes.
    /// </summary>
    public class ExtractedItem
    {
        /// <summary>
        /// The ObjectId of the block reference.
        /// </summary>
        public ObjectId BlockId { get; set; }

        /// <summary>
        /// The name of the block definition.
        /// </summary>
        public string BlockName { get; set; }

        /// <summary>
        /// The handle string of the block reference.
        /// </summary>
        public string BlockHandle { get; set; }

        /// <summary>
        /// The drawing title extracted via regex from attribute value.
        /// </summary>
        public string DrawingTitle { get; set; }

        /// <summary>
        /// The drawing index/number extracted via regex.
        /// </summary>
        public string DrawingIndex { get; set; }

        /// <summary>
        /// The total count extracted via regex (for multi-volume documents).
        /// </summary>
        public string DrawingTotal { get; set; }

        /// <summary>
        /// The original selection order index.
        /// </summary>
        public int SelectionOrder { get; set; }

        /// <summary>
        /// The base point position of the block reference.
        /// </summary>
        public Point3d Position { get; set; }

        /// <summary>
        /// The X coordinate of the position.
        /// </summary>
        public double PositionX => Position.X;

        /// <summary>
        /// The Y coordinate of the position.
        /// </summary>
        public double PositionY => Position.Y;

        /// <summary>
        /// Dictionary of attribute tag to value pairs.
        /// </summary>
        public Dictionary<string, string> Attributes { get; set; } = new();

        /// <summary>
        /// The timestamp when this item was extracted.
        /// </summary>
        public DateTime ExtractedAt { get; set; } = DateTime.Now;

        /// <summary>
        /// Whether this item is currently selected in the UI.
        /// </summary>
        public bool IsSelected { get; set; }

        /// <summary>
        /// Gets a display-friendly string for the index.
        /// </summary>
        public string DisplayIndex => string.IsNullOrEmpty(DrawingIndex) ? SelectionOrder.ToString() : DrawingIndex;

        /// <summary>
        /// Gets the primary title from attributes or extracted title.
        /// </summary>
        public string Title => !string.IsNullOrEmpty(DrawingTitle) ? DrawingTitle : BlockName;

        /// <summary>
        /// Creates a copy of this ExtractedItem.
        /// </summary>
        public ExtractedItem Clone()
        {
            return new ExtractedItem
            {
                BlockId = BlockId,
                BlockName = BlockName,
                BlockHandle = BlockHandle,
                DrawingTitle = DrawingTitle,
                DrawingIndex = DrawingIndex,
                DrawingTotal = DrawingTotal,
                SelectionOrder = SelectionOrder,
                Position = Position,
                Attributes = new Dictionary<string, string>(Attributes),
                ExtractedAt = ExtractedAt,
                IsSelected = IsSelected
            };
        }

        /// <summary>
        /// Returns a string representation of this item.
        /// </summary>
        public override string ToString()
        {
            return $"{BlockName} [{DrawingTitle}] ({PositionX:F2}, {PositionY:F2})";
        }
    }
}
