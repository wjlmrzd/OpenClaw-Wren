using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace CadAttrExtractor
{
    /// <summary>
    /// Static helper class for safe database operations using transactions.
    /// Provides wrapper methods that handle transaction lifecycle and error management.
    /// </summary>
    public static class TransactionHelper
    {
        /// <summary>
        /// Executes an action within a new transaction context.
        /// </summary>
        /// <typeparam name="T">Return type of the function.</typeparam>
        /// <param name="db">The database to work with.</param>
        /// <param name="func">The function to execute.</param>
        /// <returns>The result of the function.</returns>
        public static T Execute<T>(Database db, Func<Transaction, T> func)
        {
            using (var trans = db.TransactionManager.StartTransaction())
            {
                try
                {
                    var result = func(trans);
                    trans.Commit();
                    return result;
                }
                catch (System.Exception ex)
                {
                    trans.Abort();
                    CadAttrExtractorApp.WriteLine($"[Transaction Error] {ex.Message}");
                    throw;
                }
            }
        }

        /// <summary>
        /// Executes an action within a new transaction context.
        /// </summary>
        /// <param name="db">The database to work with.</param>
        /// <param name="action">The action to execute.</param>
        public static void Execute(Database db, Action<Transaction> action)
        {
            using (var trans = db.TransactionManager.StartTransaction())
            {
                try
                {
                    action(trans);
                    trans.Commit();
                }
                catch (System.Exception ex)
                {
                    trans.Abort();
                    CadAttrExtractorApp.WriteLine($"[Transaction Error] {ex.Message}");
                    throw;
                }
            }
        }

        /// <summary>
        /// Executes a locked document operation safely.
        /// </summary>
        /// <param name="doc">The document to lock.</param>
        /// <param name="action">The action to execute with the database.</param>
        public static void ExecuteWithLock(Document doc, Action<Database> action)
        {
            if (doc == null) return;

            var ed = doc.Editor;
            var db = doc.Database;

            using (var docLock = doc.LockDocument())
            {
                using (var trans = db.TransactionManager.StartTransaction())
                {
                    try
                    {
                        action(db);
                        trans.Commit();
                    }
                    catch (System.Exception ex)
                    {
                        trans.Abort();
                        ed.WriteMessage($"\nError: {ex.Message}");
                        CadAttrExtractorApp.WriteLine($"[Locked Transaction Error] {ex.Message}");
                        throw;
                    }
                }
            }
        }
    }

    /// <summary>
    /// Contains all AutoCAD commands for the CadAttrExtractor plugin.
    /// All commands check for valid document/editor context and handle exceptions gracefully.
    /// </summary>
    public static class Commands
    {
        private static Point3d _tableInsertPoint = Point3d.Origin;
        private static bool _pointSelected = false;

        /// <summary>
        /// Shows the main palette window.
        /// </summary>
        [CommandMethod("CTE", "_cteShow", CommandFlags.Session)]
        public static void ShowPalette()
        {
            var doc = Application.DocumentManager.MdiActiveDocument;
            if (doc == null) return;

            CadAttrExtractorApp.Instance?.ShowPalette();
            doc.Editor.WriteMessage("\n图纸目录提取器面板已显示�?);
        }

        /// <summary>
        /// Extracts attributes from selected blocks.
        /// Prompts user to select blocks and extracts specified attributes.
        /// </summary>
        [CommandMethod("CTE", "_cteExtract", CommandFlags.UsePickSet | CommandFlags.Redraw)]
        public static void ExtractAttributes()
        {
            var doc = Application.DocumentManager.MdiActiveDocument;
            if (doc == null)
            {
                CadAttrExtractorApp.WriteLine("[Extract] No active document");
                return;
            }

            var ed = doc.Editor;
            var db = doc.Database;

            try
            {
                var settings = SettingsService.Instance.Current.Extraction;

                // Prompt for block name pattern
                var blockPrompt = new PromptStringOptions("\n输入图块名称 (留空匹配所�?: ");
                blockPrompt.AllowSpaces = true;
                blockPrompt.DefaultValue = "*";
                var blockResult = ed.GetString(blockPrompt);
                if (blockResult.Status != PromptStatus.OK) return;

                var blockPattern = string.IsNullOrEmpty(blockResult.StringResult) ? "*" : blockResult.StringResult;

                // Prompt for attribute tag
                var tagPrompt = new PromptStringOptions("\n输入属性标�?(留空提取所�?: ");
                tagPrompt.AllowSpaces = true;
                var tagResult = ed.GetString(tagPrompt);
                if (tagResult.Status != PromptStatus.OK) return;

                var tagFilter = tagResult.StringResult;

                // Get selection set
                var selOpts = new PromptSelectionOptions();
                selOpts.MessageForAdding = "\n选择要提取的图块: ";
                selOpts.SingleOnly = false;

                var selResult = ed.GetSelection(selOpts, SelectionFilter());
                if (selResult.Status != PromptStatus.OK)
                {
                    ed.WriteMessage("\n未选择图块�?);
                    return;
                }

                ed.WriteMessage($"\n正在提取 {selResult.Value.Count} 个图�?..");

                var progressMeter = new ProgressMeter();
                progressMeter.Start("提取属�?);
                progressMeter.Position = 0;

                var items = new List<ExtractedItem>();
                var startTime = DateTime.Now;

                TransactionHelper.ExecuteWithLock(doc, (database) =>
                {
                    using (var trans = database.TransactionManager.StartTransaction())
                    {
                        var selectionSet = selResult.Value;
                        var index = 0;

                        foreach (SelectedObject selObj in selectionSet)
                        {
                            if (selObj.ObjectId.IsNull) continue;

                            progressMeter.Position = (int)((double)index / selectionSet.Count * 100);

                            try
                            {
                                if (selObj.ObjectId.ObjectClass.DxfName == "INSERT")
                                {
                                    var blockRef = trans.GetObject(selObj.ObjectId, OpenMode.ForRead) as BlockReference;
                                    if (blockRef != null)
                                    {
                                        var blockName = GetBlockName(blockRef, trans);
                                        if (MatchesPattern(blockName, blockPattern))
                                        {
                                            var attrs = new AttributeCollection();
                                            blockRef.AttributeCollection.ForEachEntity(aId =>
                                            {
                                                var attrRef = trans.GetObject(aId, OpenMode.ForRead) as AttributeReference;
                                                if (attrRef != null)
                                                {
                                                    attrs.AppendAttributePair(attrRef);
                                                }
                                            });

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

                                            // Extract all or specific attributes
                                            foreach (AttributeReference attr in attrs)
                                            {
                                                if (string.IsNullOrEmpty(tagFilter) ||
                                                    attr.Tag.Equals(tagFilter, StringComparison.OrdinalIgnoreCase))
                                                {
                                                    item.Attributes[attr.Tag] = attr.TextString;
                                                }
                                            }

                                            // Extract title/index/total from first attribute value
                                            if (item.Attributes.Count > 0)
                                            {
                                                var firstValue = item.Attributes.Values.FirstOrDefault();
                                                if (!string.IsNullOrEmpty(firstValue))
                                                {
                                                    var (title, idx, total) = ExtractionService.ExtractTitleIndex(
                                                        firstValue, settings.TitleRegexPatterns);
                                                    item.DrawingTitle = title;
                                                    item.DrawingIndex = idx;
                                                    item.DrawingTotal = total;
                                                }
                                            }

                                            items.Add(item);
                                        }
                                    }
                                }
                            }
                            catch (System.Exception ex)
                            {
                                CadAttrExtractorApp.WriteLine($"[Extract] Item error: {ex.Message}");
                            }

                            index++;
                        }

                        trans.Commit();
                    }
                });

                progressMeter.Stop();

                // Update ViewModel if available
                var viewModel = Views.MainView.Instance?.DataContext as ViewModels.MainViewModel;
                if (viewModel != null)
                {
                    viewModel.LoadItems(items);
                }

                var duration = DateTime.Now - startTime;
                ed.WriteMessage($"\n提取完成: {items.Count} 个项�? 耗时 {duration.TotalSeconds:F2}�?);
                CadAttrExtractorApp.WriteLine($"[Extract] Completed: {items.Count} items in {duration.TotalSeconds:F2}s");

            }
            catch (System.Exception ex)
            {
                ed.WriteMessage($"\n提取错误: {ex.Message}");
                CadAttrExtractorApp.WriteLine($"[Extract] Error: {ex.Message}\n{ex.StackTrace}");
            }
        }

        /// <summary>
        /// Sorts extracted items by coordinate using specified mode.
        /// </summary>
        [CommandMethod("CTE", "_cteSortByCoordinate", CommandFlags.Session)]
        public static void SortByCoordinate()
        {
            var doc = Application.DocumentManager.MdiActiveDocument;
            if (doc == null) return;

            var ed = doc.Editor;
            var viewModel = Views.MainView.Instance?.DataContext as ViewModels.MainViewModel;

            if (viewModel == null || viewModel.Items.Count == 0)
            {
                ed.WriteMessage("\n没有可排序的项目。请先提取属性�?);
                return;
            }

            // Prompt for sort mode
            var sortOptions = new PromptKeywordOptions("\n选择排序方式: ");
            sortOptions.AddKeywords("上左下右 上右下左 左上右下 左上左下 选择顺序 取消");
            sortOptions.Keywords.Default = "上左下右";

            var sortResult = ed.GetKeywords(sortOptions);
            if (sortResult.Status != PromptStatus.OK)
            {
                if (sortResult.Status == PromptStatus.Keyword)
                {
                    ed.WriteMessage("\n排序已取消�?);
                }
                return;
            }

            var sortMode = sortResult.StringResult switch
            {
                "上左下右" => SortMode.TopToBottomLeftToRight,
                "上右下左" => SortMode.LeftToRightTopToBottom,
                "左上右下" => SortMode.LeftToRightBottomToTop,
                "左上左下" => SortMode.TopToBottomLeftToRight,
                "选择顺序" => SortMode.SelectionOrder,
                _ => SortMode.TopToBottomLeftToRight
            };

            ed.WriteMessage($"\n正在排序...");

            var items = viewModel.Items.Select(vm => vm.Model).ToList();
            SortService.Sort(items, sortMode, SettingsService.Instance.Current.Extraction.Tolerance);

            // Update selection orders
            for (int i = 0; i < items.Count; i++)
            {
                items[i].SelectionOrder = i;
            }

            viewModel.LoadItems(items);
            ed.WriteMessage($"\n排序完成: {items.Count} 个项�?);
            CadAttrExtractorApp.WriteLine($"[Sort] Sorted {items.Count} items with mode {sortMode}");
        }

        /// <summary>
        /// Generates a DWG table at the specified insertion point.
        /// </summary>
        [CommandMethod("CTE", "_cteGenerateTable", CommandFlags.UsePickSet | CommandFlags.Redraw)]
        public static void GenerateTable()
        {
            var doc = Application.DocumentManager.MdiActiveDocument;
            if (doc == null) return;

            var ed = doc.Editor;
            var db = doc.Database;
            var viewModel = Views.MainView.Instance?.DataContext as ViewModels.MainViewModel;

            if (viewModel == null || viewModel.Items.Count == 0)
            {
                ed.WriteMessage("\n没有可生成表格的数据。请先提取属性�?);
                return;
            }

            try
            {
                // Get insertion point
                var pointOpts = new PromptPointOptions("\n拾取表格插入�? ");
                var pointResult = ed.GetPoint(pointOpts);
                if (pointResult.Status != PromptStatus.OK)
                {
                    ed.WriteMessage("\n已取消�?);
                    return;
                }

                _tableInsertPoint = pointResult.Value;
                _pointSelected = true;

                ed.WriteMessage($"\n插入�? ({_tableInsertPoint.X:F2}, {_tableInsertPoint.Y:F2}, {_tableInsertPoint.Z:F2})");

                var items = viewModel.Items.Select(vm => vm.Model).ToList();
                var settings = SettingsService.Instance.Current.Table;

                TransactionHelper.ExecuteWithLock(doc, (database) =>
                {
                    TableGenerationService.GenerateTable(database, items, _tableInsertPoint, settings);
                });

                ed.WriteMessage("\n表格生成完成�?);
                CadAttrExtractorApp.WriteLine($"[Table] Generated table with {items.Count} rows at ({_tableInsertPoint.X:F2}, {_tableInsertPoint.Y:F2})");

            }
            catch (System.Exception ex)
            {
                ed.WriteMessage($"\n表格生成错误: {ex.Message}");
                CadAttrExtractorApp.WriteLine($"[Table] Error: {ex.Message}\n{ex.StackTrace}");
            }
        }

        /// <summary>
        /// Exports extracted items to an Excel file.
        /// </summary>
        [CommandMethod("CTE", "_cteExportExcel", CommandFlags.Session)]
        public static void ExportToExcel()
        {
            var doc = Application.DocumentManager.MdiActiveDocument;
            if (doc == null) return;

            var ed = doc.Editor;
            var viewModel = Views.MainView.Instance?.DataContext as ViewModels.MainViewModel;

            if (viewModel == null || viewModel.Items.Count == 0)
            {
                ed.WriteMessage("\n没有可导出的数据。请先提取属性�?);
                return;
            }

            try
            {
                var settings = SettingsService.Instance.Current.Export;

                // Prompt for output file
                var saveDialog = new Microsoft.Win32.SaveFileDialog
                {
                    Filter = "Excel Files (*.xlsx)|*.xlsx",
                    DefaultExt = ".xlsx",
                    FileName = $"图纸目录_{DateTime.Now:yyyyMMdd_HHmmss}",
                    InitialDirectory = string.IsNullOrEmpty(settings.LastExportFolder)
                        ? Environment.GetFolderPath(Environment.SpecialFolder.Desktop)
                        : settings.LastExportFolder
                };

                if (saveDialog.ShowDialog() == true)
                {
                    var items = viewModel.Items.Select(vm => vm.Model).ToList();
                    var templatePath = settings.ExcelTemplatePath;

                    ed.WriteMessage("\n正在导出�?Excel...");

                    if (File.Exists(templatePath))
                    {
                        ExportService.ExportToExcel(items, templatePath, saveDialog.FileName, settings);
                    }
                    else
                    {
                        ExportService.ExportToExcelNew(items, saveDialog.FileName, settings);
                    }

                    settings.LastExportFolder = Path.GetDirectoryName(saveDialog.FileName);
                    SettingsService.Instance.Save();

                    ed.WriteMessage($"\nExcel 导出完成: {saveDialog.FileName}");
                    CadAttrExtractorApp.WriteLine($"[Export] Excel exported to {saveDialog.FileName}");
                }

            }
            catch (System.Exception ex)
            {
                ed.WriteMessage($"\nExcel 导出错误: {ex.Message}");
                CadAttrExtractorApp.WriteLine($"[Export] Excel error: {ex.Message}\n{ex.StackTrace}");
            }
        }

        /// <summary>
        /// Exports extracted items to a Word file.
        /// </summary>
        [CommandMethod("CTE", "_cteExportWord", CommandFlags.Session)]
        public static void ExportToWord()
        {
            var doc = Application.DocumentManager.MdiActiveDocument;
            if (doc == null) return;

            var ed = doc.Editor;
            var viewModel = Views.MainView.Instance?.DataContext as ViewModels.MainViewModel;

            if (viewModel == null || viewModel.Items.Count == 0)
            {
                ed.WriteMessage("\n没有可导出的数据。请先提取属性�?);
                return;
            }

            try
            {
                var settings = SettingsService.Instance.Current.Export;

                // Prompt for output file
                var saveDialog = new Microsoft.Win32.SaveFileDialog
                {
                    Filter = "Word Files (*.docx)|*.docx",
                    DefaultExt = ".docx",
                    FileName = $"图纸目录_{DateTime.Now:yyyyMMdd_HHmmss}",
                    InitialDirectory = string.IsNullOrEmpty(settings.LastExportFolder)
                        ? Environment.GetFolderPath(Environment.SpecialFolder.Desktop)
                        : settings.LastExportFolder
                };

                if (saveDialog.ShowDialog() == true)
                {
                    var items = viewModel.Items.Select(vm => vm.Model).ToList();
                    var templatePath = settings.WordTemplatePath;

                    ed.WriteMessage("\n正在导出�?Word...");

                    if (File.Exists(templatePath))
                    {
                        ExportService.ExportToWord(items, templatePath, saveDialog.FileName, settings);
                    }
                    else
                    {
                        ExportService.ExportToWordNew(items, saveDialog.FileName, settings);
                    }

                    settings.LastExportFolder = Path.GetDirectoryName(saveDialog.FileName);
                    SettingsService.Instance.Save();

                    ed.WriteMessage($"\nWord 导出完成: {saveDialog.FileName}");
                    CadAttrExtractorApp.WriteLine($"[Export] Word exported to {saveDialog.FileName}");
                }

            }
            catch (System.Exception ex)
            {
                ed.WriteMessage($"\nWord 导出错误: {ex.Message}");
                CadAttrExtractorApp.WriteLine($"[Export] Word error: {ex.Message}\n{ex.StackTrace}");
            }
        }

        /// <summary>
        /// Opens the settings dialog.
        /// </summary>
        [CommandMethod("CTE", "_cteSettings", CommandFlags.Session)]
        public static void OpenSettings()
        {
            var doc = Application.DocumentManager.MdiActiveDocument;
            if (doc == null) return;

            try
            {
                var settingsDialog = new Views.SettingsDialog();
                settingsDialog.Owner = Application.MainWindow;
                Application.ShowModalWindow(settingsDialog);
            }
            catch (System.Exception ex)
            {
                doc.Editor.WriteMessage($"\n打开设置窗口错误: {ex.Message}");
                CadAttrExtractorApp.WriteLine($"[Settings] Dialog error: {ex.Message}");
            }
        }

        /// <summary>
        /// Shows the about dialog.
        /// </summary>
        [CommandMethod("CTE", "_cteAbout", CommandFlags.Session)]
        public static void ShowAbout()
        {
            var aboutDialog = new Views.AboutDialog();
            aboutDialog.Owner = Application.MainWindow;
            Application.ShowModalWindow(aboutDialog);
        }

        /// <summary>
        /// Picks a point for table insertion.
        /// </summary>
        [CommandMethod("CTE", "_ctePickPoint", CommandFlags.UsePickSet)]
        public static void PickTablePoint()
        {
            var doc = Application.DocumentManager.MdiActiveDocument;
            if (doc == null) return;

            var ed = doc.Editor;

            var pointOpts = new PromptPointOptions("\n拾取表格插入�? ");
            var pointResult = ed.GetPoint(pointOpts);
            if (pointResult.Status == PromptStatus.OK)
            {
                _tableInsertPoint = pointResult.Value;
                _pointSelected = true;
                ed.WriteMessage($"\n插入点已设置: ({_tableInsertPoint.X:F2}, {_tableInsertPoint.Y:F2})");

                var viewModel = Views.MainView.Instance?.DataContext as ViewModels.MainViewModel;
                viewModel?.SetInsertionPoint(_tableInsertPoint);
            }
        }

        // Helper methods

        private static SelectionFilter SelectionFilter()
        {
            var filterTypes = new TypedValue[]
            {
                new TypedValue((int)DxfCode.Start, "INSERT")
            };
            return new SelectionFilter(filterTypes);
        }

        private static string GetBlockName(BlockReference blockRef, Transaction trans)
        {
            var db = blockRef.Database;
            var blockTable = (BlockTable)trans.GetObject(db.BlockTableId, OpenMode.ForRead);
            var blockTableRecord = (BlockTableRecord)trans.GetObject(blockRef.BlockTableRecord, OpenMode.ForRead);
            return blockTableRecord.Name;
        }

        private static bool MatchesPattern(string name, string pattern)
        {
            if (string.IsNullOrEmpty(pattern) || pattern == "*") return true;
            if (pattern.Contains("*") || pattern.Contains("?"))
            {
                return WildcardMatch(name, pattern);
            }
            return name.Equals(pattern, StringComparison.OrdinalIgnoreCase);
        }

        private static bool WildcardMatch(string input, string pattern)
        {
            var regexPattern = "^" + System.Text.RegularExpressions.Regex.Escape(pattern)
                .Replace("\\*", ".*")
                .Replace("\\?", ".") + "$";
            return System.Text.RegularExpressions.Regex.IsMatch(input, regexPattern,
                System.Text.RegularExpressions.RegexOptions.IgnoreCase);
        }
    }
}
