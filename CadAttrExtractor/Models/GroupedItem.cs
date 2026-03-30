using System;
using System.Collections.Generic;
using System.Linq;

namespace CadAttrExtractor
{
    /// <summary>
    /// Represents a group of extracted items with the same title.
    /// </summary>
    public class GroupedItem
    {
        /// <summary>
        /// The title of the group (extracted from drawing title).
        /// </summary>
        public string Title { get; set; }

        /// <summary>
        /// The index number of this group.
        /// </summary>
        public string Index { get; set; }

        /// <summary>
        /// The total count (for multi-volume documents).
        /// </summary>
        public string Total { get; set; }

        /// <summary>
        /// The number of members in this group.
        /// </summary>
        public int Count { get; set; }

        /// <summary>
        /// The list of members in this group.
        /// </summary>
        public List<ExtractedItem> Members { get; set; } = new();

        /// <summary>
        /// Gets a display-friendly text for this group.
        /// </summary>
        public string DisplayText
        {
            get
            {
                if (string.IsNullOrEmpty(Total))
                {
                    return string.IsNullOrEmpty(Index)
                        ? Title
                        : $"{Title} ({Index})";
                }
                return $"{Title} ç¬¬{Index}å†?å…±{Count}å†?;
            }
        }

        /// <summary>
        /// Gets the first member of the group.
        /// </summary>
        public ExtractedItem FirstMember => Members.FirstOrDefault();

        /// <summary>
        /// Gets the position of the first member.
        /// </summary>
        public double PositionX => FirstMember?.PositionX ?? 0;
        public double PositionY => FirstMember?.PositionY ?? 0;

        /// <summary>
        /// Creates a GroupedItem from a list of items.
        /// </summary>
        public static GroupedItem Create(ExtractedItem item)
        {
            return new GroupedItem
            {
                Title = item.DrawingTitle ?? item.BlockName,
                Index = item.DrawingIndex,
                Total = item.DrawingTotal,
                Count = 1,
                Members = new List<ExtractedItem> { item }
            };
        }

        /// <summary>
        /// Adds a member to this group.
        /// </summary>
        public void AddMember(ExtractedItem item)
        {
            Members.Add(item);
            Count = Members.Count;
        }

        /// <summary>
        /// Returns a string representation of this group.
        /// </summary>
        public override string ToString()
        {
            return $"{DisplayText} [{Count} items]";
        }
    }
}
