#!/usr/bin/env python3
import os, json

vault = r'E:\software\Obsidian\vault'

# Create subdirectories for expanded automation tools
base = os.path.join(vault, 'knowledge', '工程知识', '自动化工具')
dirs_to_create = [
    '文档处理',
    '数据报表',
    '文件管理',
    '流程消息',
    '工程专用',
    '开发运维',
]

for d in dirs_to_create:
    full = os.path.join(base, d)
    os.makedirs(full, exist_ok=True)
    # Create a placeholder index note
    idx_path = os.path.join(full, '00-索引.md')
    if not os.path.exists(idx_path):
        with open(idx_path, 'w', encoding='utf-8') as f:
            f.write(f'# {d}\n\n> 占位笔记 - 待填充内容\n')

print('Dirs created:', dirs_to_create)

# Create the canvas expansion plan
canvas_path = os.path.join(base, '自动化工具扩展蓝图.canvas')
canvas = {
    "nodes": [
        {
            "id": "root",
            "type": "text",
            "data": {
                "text": "# 🔧 自动化工具扩展蓝图\n\n当前结构单薄（3个目录），以下为可选扩展方向。优先级由你来定。"
            }
        },
        {
            "id": "doc",
            "type": "text",
            "x": -600,
            "y": 200,
            "data": {
                "text": "## 📄 文档处理\n- PDF/OCR 自动化\n- 格式转换 (MD↔Word↔PDF)\n- 模板引擎"
            }
        },
        {
            "id": "doc_sub",
            "type": "text",
            "x": -600,
            "y": 450,
            "data": {
                "text": "→ 目录: `文档处理/`\n→ 优先级: ★★★"
            }
        },
        {
            "id": "data",
            "type": "text",
            "x": -200,
            "y": 200,
            "data": {
                "text": "## 📊 数据与报表\n- 数据采集 (爬虫/API)\n- 报表生成 (图表+邮件)\n- 数据库操作"
            }
        },
        {
            "id": "data_sub",
            "type": "text",
            "x": -200,
            "y": 450,
            "data": {
                "text": "→ 目录: `数据报表/`\n→ 优先级: ★★★★"
            }
        },
        {
            "id": "file",
            "type": "text",
            "x": 200,
            "y": 200,
            "data": {
                "text": "## 🗂️ 文件管理\n- 文件归档 (自动分类)\n- 版本控制 (Git 自动化)\n- 云端同步 (OneDrive/飞书)"
            }
        },
        {
            "id": "file_sub",
            "type": "text",
            "x": 200,
            "y": 450,
            "data": {
                "text": "→ 目录: `文件管理/`\n→ 优先级: ★★★"
            }
        },
        {
            "id": "workflow",
            "type": "text",
            "x": 600,
            "y": 200,
            "data": {
                "text": "## 🤖 流程与消息\n- 工作流触发器\n- 会议助手\n- 邮件自动化"
            }
        },
        {
            "id": "workflow_sub",
            "type": "text",
            "x": 600,
            "y": 450,
            "data": {
                "text": "→ 目录: `流程消息/`\n→ 优先级: ★★★★"
            }
        },
        {
            "id": "eng",
            "type": "text",
            "x": -400,
            "y": 700,
            "data": {
                "text": "## 📐 工程专用\n- CAD 批处理\n- BOM/物料清单\n- 图纸管理"
            }
        },
        {
            "id": "eng_sub",
            "type": "text",
            "x": -400,
            "y": 950,
            "data": {
                "text": "→ 目录: `工程专用/`\n→ 优先级: ★★★ (看你用不用CAD)"
            }
        },
        {
            "id": "devops",
            "type": "text",
            "x": 200,
            "y": 700,
            "data": {
                "text": "## 🧰 开发运维\n- 脚本市场\n- 定时任务编排\n- API 封装"
            }
        },
        {
            "id": "devops_sub",
            "type": "text",
            "x": 200,
            "y": 950,
            "data": {
                "text": "→ 目录: `开发运维/`\n→ 优先级: ★★★★ (和现有工作流衔接)"
            }
        },
        {
            "id": "existing",
            "type": "text",
            "x": -100,
            "y": -200,
            "data": {
                "text": "### 📁 现有目录\n- PowerShell/ ← 脚本核心\n- 插件开发/ ← VS Code CAD\n- 工作流/ ← CI/CD 编排\n\n**→ 扩展后总数: 9 个子目录**"
            }
        }
    ],
    "edges": [
        {"id": "e1", "fromNode": "root", "toNode": "existing"},
        {"id": "e2", "fromNode": "root", "toNode": "doc"},
        {"id": "e3", "fromNode": "doc", "toNode": "doc_sub"},
        {"id": "e4", "fromNode": "root", "toNode": "data"},
        {"id": "e5", "fromNode": "data", "toNode": "data_sub"},
        {"id": "e6", "fromNode": "root", "toNode": "file"},
        {"id": "e7", "fromNode": "file", "toNode": "file_sub"},
        {"id": "e8", "fromNode": "root", "toNode": "workflow"},
        {"id": "e9", "fromNode": "workflow", "toNode": "workflow_sub"},
        {"id": "e10", "fromNode": "root", "toNode": "eng"},
        {"id": "e11", "fromNode": "eng", "toNode": "eng_sub"},
        {"id": "e12", "fromNode": "root", "toNode": "devops"},
        {"id": "e13", "fromNode": "devops", "toNode": "devops_sub"},
        {"id": "e14", "fromNode": "devops", "toNode": "workflow"},
        {"id": "e15", "fromNode": "data", "toNode": "file"}
    ]
}

with open(canvas_path, 'w', encoding='utf-8') as f:
    json.dump(canvas, f, ensure_ascii=False, indent='\t')

print('Canvas created:', canvas_path)
