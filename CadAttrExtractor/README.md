# CadAttrExtractor

> AutoCAD 图块属性提取器 — v2.0 (MVVM 重构版)

## 需求规格（v2.0, 2026-04-01 确认）

### 目标平台
- **CAD 版本**: AutoCAD 2020, 2022, 2024（优先测试 2022）
- **.NET**: .NET Framework 4.8 + .NET 8.0 双目标
- **不支持**: 中望 ZWCAD（暂无计划）

### 核心功能
1. **图块属性提取** — SelectionFilter + 正则表达式分组
2. **坐标排序** — 4种模式（上下左右/左右上下/左右下上/选择顺序）
3. **DWG 表格生成** — 支持按固定行数分页
4. **批量处理** — 多文件批量提取
5. **模板导出** — Excel/Word 占位符模板（兼容 WPS + 旧版 Office）
6. **CSV 简化导出** — 可选功能

### UI：WPF PaletteSet 浮动面板
- 5个标签页：**提取 / 预览 / 表格 / 导出 / 设置**
- 实时预览 + 拖拽排序
- 浅色/深色主题切换

### 导出占位符
`{{DrawingTitle}}`, `{{DrawingIndex}}`, `{{TotalCount}}`, `{{TotalPages}}`, `{{CurrentPage}}`, `{{ExtractDate}}`, `{{RowIndex}}`

## 系统要求
- Windows 10/11 x64
- AutoCAD 2020/2022/2024
- .NET Framework 4.8 + .NET 8.0
