---
title: {{TITLE}}
source: "{{SOURCE_NAME}}"           # 原始文档规范名称
version: "{{VERSION}}"              # 版本编号 (如: v2.1, Rev.03)
section: "{{SECTION}}"             # 来源章节/条款
scope: "{{SCOPE}}"                  # 适用范围
category: "{{CATEGORY}}"            # 专业分类: 结构/市政/建筑/机电
docId: "{{DOC_ID}}"                # 文档唯一标识
status: active                      # 状态: active/superseded/draft
tags:
  - 原子
  - {{SOURCE_TAG}}
  - {{CATEGORY}}
created: {{CREATED_DATE}}
updated: {{UPDATED_DATE}}
model: glm-5
---

# {{TITLE}}

## 原子内容

{{ATOMIC_CONTENT}}

## 关联条款

{{RELATED_CLAUSES}}

## 关联组合

| 组合笔记 | 关联理由 | 创建日期 |
|---------|---------|---------|
| — | — | — |

## 来源追溯

- **文档**: [[{{SOURCE_LINK}}]]
- **原文条款**: {{SECTION}}
- **版本**: {{VERSION}}
- **生效日期**: {{EFFECTIVE_DATE}}

## 适用范围说明

{{SCOPE_DESCRIPTION}}

## 关联原子笔记

- [[原子笔记1]] - 关联理由
- [[原子笔记2]] - 关联理由

## 备注

{{NOTES}}

---

## 格式规范说明

> ⚠️ **重要**：保存时必须严格遵守以下格式要求

### 表格格式要求
- **必须**：原规范表格格式（包括列数、列名、单元格内容、计量单位）
- **禁止**：擅自合并/拆分单元格、修改列名、改变计量单位
- **允许**：添加行号列（可选）、在备注列添加中文说明

### 图片处理规则
- **图片保持原样**：不进行格式转换、不压缩、不重命名
- **引用格式**：`![](path/to/image.png)`
- **禁止**：对图片内容进行文字描述转换

---

**原子笔记ID**: {{ATOMIC_ID}}
**来源文档**: {{SOURCE_NAME}} {{VERSION}}
**管理模型**: glm-5
