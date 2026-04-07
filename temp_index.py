#!/usr/bin/env python3
import os, json

vault = r'E:\software\Obsidian\vault'
base = os.path.join(vault, 'knowledge', '工程知识', '自动化工具')

# Build index content
index_content = '''# 🔧 自动化工具

> 专注通用自动化办公脚本索引

## 内容结构

| 主题 | 说明 |
|------|------|
| [[PowerShell/]] | PowerShell 脚本索引 |
| [[插件开发/]] | VS Code 开发AutoCAD 插件 |
| [[工作流/]] | 自动化工作流与CI/CD |
| [[文档处理/]] | PDF/OCR、格式转换、模板引擎 |
| [[数据报表/]] | 数据采集、报表生成、数据库操作 |
| [[文件管理/]] | 文件归档、版本控制、云端同步 |
| [[流程消息/]] | 工作流触发器、会议助手、邮件自动化 |
| [[工程专用/]] | CAD批处理、BOM物料清单、图纸管理 |
| [[开发运维/]] | 脚本市场、定时任务编排、API封装 |

---

## 🗺️ 可视化蓝图

> [!canvas]+ 自动化工具扩展蓝图
> [[自动化工具扩展蓝图.canvas]]

---

*自动化工具笔记系统 - Wren 的第二大脑*
'''

idx_path = os.path.join(base, '00-自动化工具索引.md')
with open(idx_path, 'w', encoding='utf-8') as f:
    f.write(index_content)

print('Index updated:', idx_path)
