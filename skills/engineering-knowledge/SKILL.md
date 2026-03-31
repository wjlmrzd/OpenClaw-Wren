---
name: engineering-knowledge
description: 工程知识管理和检索技能。用于：(1) 检索工程知识库内容（CAD、自动化、架构、工艺流程）；(2) 解析工程文档并创建原子笔记；(3) OCR识别扫描文档；(4) 管理工程知识篇章。触发词：搜索工程知识、工程文档、CAD笔记、OCR识别、解析文档。
---

# Engineering Knowledge Management

工程知识篇章管理，使用 glm-5 模型专业化处理工程领域知识。

## 核心功能

### 1. 知识检索

**主会话调用**:
```
搜索工程知识中关于 [关键词] 的内容
```

**分类检索**:
| 分类 | 参数 | 示例 |
|------|------|------|
| CAD与建模 | cad | 属性块、动态块 |
| 自动化工具 | automation | PowerShell、批量处理 |
| 系统架构 | architecture | 架构设计 |
| 工艺流程 | process | 工程规范 |
| 原子笔记 | atomic | 按条款拆分的内容 |
| 待解析 | pending | 待处理的文档 |

**脚本执行**:
```powershell
.\search-engineering-knowledge.ps1 -Query "[关键词]" -Category [分类] -ShowContent
```

### 2. 文档解析

当用户发送 PDF、图片或文档时：

1. 使用 summarize 技能提取内容
2. 按条款分割为原子笔记
3. 标注来源信息（文档编号、版本、条款）
4. 保存到 `knowledge/工程知识/00-Inbox/`

### 3. OCR 识别

**使用 PaddleOCR API**:
```powershell
.\ocr-processor.ps1 -ImagePath "[图片路径]" -OutputPath "[输出路径]"
```

**环境变量**: 需要 `PADDLEOCR_ACCESS_TOKEN`

### 4. 原子笔记格式

每个原子笔记必须包含：
```markdown
---
title: [条款标题]
source: "[原始文档规范名称]"
version: "[版本编号]"
section: "[条款编号]"
scope: "[适用范围]"
category: [专业分类]
docId: [文档唯一ID]
status: active|draft|superseded
tags: [标签]
created: YYYY-MM-DD
---

# [条款标题]

## 原子内容
[条款具体内容]

## 关联条款
- [[文档ID_条款号]] - 上级/下级/关联

## 来源追溯
- 文档: [[文档库/文档名]]
- 原文条款: [条款号]
- 版本: [版本]
```

## 写入规范

**重要**: 所有笔记必须先进入 Inbox！

1. 用户要求写入笔记 → 统一先进入 `00-Inbox/`
2. 由知识整理员（Cron）负责从 Inbox 归档到正式目录
3. **禁止**直接将笔记写入正式目录（绕过 Inbox）

## 目录结构

```
knowledge/工程知识/
├── 00-Inbox/              # 新笔记缓冲区（待整理）
├── CAD与建模/             # CAD 建模相关知识
├── 自动化工具/            # 脚本、工具开发
├── 系统架构/              # 系统设计和架构
├── 工艺流程/              # 工程工艺流程
├── 原子笔记/              # 按条款拆分的原子内容
└── 文档库/                # 原始文档元信息
```

## 监控配置

- **监控文件夹**: `E:\EngineeringDocs`
- **Cron 任务**: 每天 02:30 自动扫描
- **状态文件**: `memory/doc-watcher-state.json`

## 模型分工

| 任务类型 | 模型 | 说明 |
|----------|------|------|
| 工程知识笔记创建 | glm-5 | CAD、脚本、工具等技术文档 |
| 工程复盘分析 | glm-5 | 项目复盘、问题分析 |
| 知识库检索 | qwen3.5-plus | 快速检索和回答 |

## 关联知识

与主知识库互通：
- 使用 [[知识/相关概念]] 建立双向链接
- 工程实践 ↔ 通用理论
