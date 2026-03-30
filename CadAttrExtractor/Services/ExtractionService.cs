using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;

namespace CadAttrExtractor
{
    /// <summary>
    /// Service for extracting attributes from AutoCAD blocks.
    /// </summary>
    public static class ExtractionService
    {
        /// <summary>
        /// Extracts attributes from blocks in the current selection.
        /// </summary>
        /// <param name="ed">The AutoCAD editor.</param>
        /// <param name="blockNamePattern">Pattern for filtering block names.</param>
        /// <param name="attributeTag">Specific attribute tag to extract (or null for all).</param>
        /// <param name="filter">Optional selection filter.</param>
        /// <param name="cancellationToken">Optional cancellation token.</param>
        /// <returns>The extraction result.</returns>
        public static ExtractionResult ExtractAttributes(
            Editor ed,
            string blockNamePattern = "*",
            string attributeTag = null,
            SelectionFilter filter = null,
            System.Threading.CancellationToken? cancellationToken = null)
        {
            var result = new ExtractionResult
            {
                BlockNameFilter = blockNamePattern,
                AttributeTagFilter = attributeTag
            };

            var startTime = DateTime.Now;

            try
            {
                // Get selection
                var selOpts = new PromptSelectionOptions();
                selOpts.MessageForAdding = "\n选择要提取的图块: ";

                PromptSelectionResult selResult;
                if (filter != null)
                {
                    selResult = ed.GetSelection(selOpts, filter);
                }
                else
                {
                    selResult = ed.GetSelection(selOpts);
                }

                if (selResult.Status != PromptStatus.OK)
                {
                    result.ErrorMessage = "用户取消选择";
                    return result;
                }

                var selectionSet = selResult.Value;
                var settings = SettingsService.Instance.Current.Extraction;
                var items = new List<ExtractedItem>();

                // Setup progress meter
                using (var progressMeter = new ProgressMeter())
                {
                    progressMeter.Start("提取属�?);
                    progressMeter.SetLimit(selectionSet.Count);

                    var db = ed.Document.Database;
                    using (var trans = db.TransactionManager.StartTransaction())
                    {
                        var index = 0;

                        foreach (SelectedObject selObj in selectionSet)
                        {
                            if (cancellationToken?.IsCancellationRequested == true)
                            {
                                result.ErrorMessage = "操作已取�?;
                                break;
                            }

                            if (selObj.ObjectId.IsNull) continue;

                            progressMeter.MeterProgress();

                            try
                            {
                                if (selObj.ObjectId.ObjectClass.DxfName == "INSERT")
                                {
                                    var blockRef = trans.GetObject(selObj.ObjectId, OpenMode.ForRead) as BlockReference;
                                    if (blockRef != null)
                                    {
                                        var blockName = GetBlockName(blockRef, trans);

                                        // Check if block matches pattern
                                        if (!MatchesPattern(blockName, blockNamePattern))
                                            continue;

                                        // Check for anonymous blocks
                                        if (!settings.IncludeAnonymousBlocks && blockName.StartsWith("*"))
                                            continue;

                                        var item = ExtractFromBlock(blockRef, trans, index, settings);
                                        if (item != null)
                                        {
                                            items.Add(item);
                                        }
                                    }
                                }
                            }
                            catch (System.Exception ex)
                            {
                                CadAttrExtractorApp.WriteLine($"[Extract] Block error: {ex.Message}");
                            }

                            index++;
                        }

                        trans.Commit();
                    }

                    progressMeter.Stop();
                }

                result.Items = items;
                result.ExtractionDuration = DateTime.Now - startTime;
                result.Success = true;

                CadAttrExtractorApp.WriteLine(
                    $"[Extract] Extracted {items.Count} items in {result.ExtractionDuration.TotalSeconds:F2}s");
            }
            catch (Autodesk.AutoCAD.Runtime.Exception ex)
            {
                result.ErrorMessage = $"AutoCAD错误: {ex.Message}";
                CadAttrExtractorApp.WriteLine($"[Extract] AutoCAD error: {ex.Message}");
            }
            catch (System.Exception ex)
            {
                result.ErrorMessage = ex.Message;
                CadAttrExtractorApp.WriteLine($"[Extract] Error: {ex.Message}\n{ex.StackTrace}");
            }

            result.ExtractedAt = DateTime.Now;
            return result;
        }

        /// <summary>
        /// Extracts a single item from a block reference.
        /// </summary>
        private static ExtractedItem ExtractFromBlock(
            BlockReference blockRef,
            Transaction trans,
            int index,
            ExtractionSettings settings)
        {
            var blockName = GetBlockName(blockRef, trans);
            var item = new ExtractedItem
            {
                BlockId = blockRef.Id,
                BlockName = blockName,
                BlockHandle = blockRef.Handle.ToString(),
                Position = blockRef.Position,
                SelectionOrder = index,
                Attributes = new Dictionary<string, string>(),
                ExtractedAt = DateTime.Now,
                IsSelected = true
            };

            // Extract attributes from the block
            var attrs = new AttributeCollection();
            blockRef.AttributeCollection.ForEachEntity(aId =>
            {
                try
                {
                    var attrRef = trans.GetObject(aId, OpenMode.ForRead) as AttributeReference;
                    if (attrRef != null && !attrRef.IsConstant)
                    {
                        item.Attributes[attrRef.Tag] = attrRef.TextString;
                        attrs.AppendAttributePair(attrRef);
                    }
                }
                catch { }
            });

            // Extract title/index/total from attribute values
            if (item.Attributes.Count > 0)
            {
                var (title, idx, total) = ExtractTitleIndex(
                    item.Attributes.Values.FirstOrDefault() ?? string.Empty,
                    settings.TitleRegexPatterns);

                item.DrawingTitle = title;
                item.DrawingIndex = idx;
                item.DrawingTotal = total;
            }

            return item;
        }

        /// <summary>
        /// Extracts title, index, and total from text using regex patterns.
        /// </summary>
        /// <param name="text">The input text to parse.</param>
        /// <param name="patterns">List of regex patterns to try.</param>
        /// <returns>A tuple of (title, index, total).</returns>
        public static (string Title, string Index, string Total) ExtractTitleIndex(
            string text,
            List<string> patterns = null)
        {
            patterns ??= SettingsService.Instance.Current.Extraction.TitleRegexPatterns;

            foreach (var pattern in patterns)
            {
                try
                {
                    var regex = new Regex(pattern, RegexOptions.IgnoreCase);
                    var match = regex.Match(text);

                    if (match.Success)
                    {
                        var title = match.Groups["Title"]?.Value?.Trim() ?? text;
                        var index = match.Groups["Index"]?.Value?.Trim();
                        var total = match.Groups["Total"]?.Value?.Trim();

                        // If no title group, use the whole match
                        if (string.IsNullOrEmpty(title))
                        {
                            title = text;
                        }

                        return (title, index, total);
                    }
                }
                catch (System.Exception ex)
                {
                    CadAttrExtractorApp.WriteLine($"[Extract] Regex error: {ex.Message}");
                }
            }

            // Default: use whole text as title
            return (text, null, null);
        }

        /// <summary>
        /// Groups items by their drawing title.
        /// </summary>
        /// <param name="items">The items to group.</param>
        /// <returns>List of grouped items.</returns>
        public static List<GroupedItem> GroupByTitle(List<ExtractedItem> items)
        {
            var groups = new Dictionary<string, GroupedItem>(StringComparer.OrdinalIgnoreCase);

            foreach (var item in items)
            {
                var key = item.DrawingTitle ?? item.BlockName;

                if (!groups.TryGetValue(key, out var group))
                {
                    group = GroupedItem.Create(item);
                    groups[key] = group;
                }
                else
                {
                    group.AddMember(item);
                }
            }

            return groups.Values.ToList();
        }

        /// <summary>
        /// Gets blocks with attributes from the database.
        /// </summary>
        public static List<ObjectId> GetBlocksWithAttributes(
            Database db,
            string blockNamePattern = "*",
            string attributeTag = null)
        {
            var blockIds = new List<ObjectId>();

            TransactionHelper.Execute(db, trans =>
            {
                var bt = (BlockTable)trans.GetObject(db.BlockTableId, OpenMode.ForRead);

                foreach (ObjectId btrId in bt)
                {
                    var btr = (BlockTableRecord)trans.GetObject(btrId, OpenMode.ForRead);

                    if (!btr.HasAttributes) continue;
                    if (!MatchesPattern(btr.Name, blockNamePattern)) continue;

                    // Check if anonymous blocks should be excluded
                    if (btr.Name.StartsWith("*") && !SettingsService.Instance.Current.Extraction.IncludeAnonymousBlocks)
                        continue;

                    blockIds.Add(btrId);
                }
            });

            return blockIds;
        }

        /// <summary>
        /// Extracts a specific attribute value from an attribute collection.
        /// </summary>
        public static string ExtractAttributeValue(AttributeCollection attrs, string tag)
        {
            foreach (ObjectId attrId in attrs)
            {
                try
                {
                    using (var attrRef = attrId.Open(OpenMode.ForRead) as AttributeReference)
                    {
                        if (attrRef != null && attrRef.Tag.Equals(tag, StringComparison.OrdinalIgnoreCase))
                        {
                            return attrRef.TextString;
                        }
                    }
                }
                catch { }
            }
            return null;
        }

        /// <summary>
        /// Gets the block name from a BlockReference.
        /// </summary>
        private static string GetBlockName(BlockReference blockRef, Transaction trans)
        {
            var btr = (BlockTableRecord)trans.GetObject(blockRef.BlockTableRecord, OpenMode.ForRead);
            return btr.Name;
        }

        /// <summary>
        /// Checks if a name matches a wildcard pattern.
        /// </summary>
        private static bool MatchesPattern(string name, string pattern)
        {
            if (string.IsNullOrEmpty(pattern) || pattern == "*") return true;

            if (pattern.Contains("*") || pattern.Contains("?"))
            {
                var regexPattern = "^" + Regex.Escape(pattern)
                    .Replace("\\*", ".*")
                    .Replace("\\?", ".") + "$";
                return Regex.IsMatch(name, regexPattern, RegexOptions.IgnoreCase);
            }

            return name.Equals(pattern, StringComparison.OrdinalIgnoreCase);
        }
    }
}
