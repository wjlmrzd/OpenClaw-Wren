# Obsidian 笔记任务模型使用策略

**重要**: 此策略**不修改任何现有 Cron 任务或 Agent 配置**。仅作为 Obsidian 笔记操作的运行时配置指导。

---

## 适用范围

当使用 **Obsidian CLI** 或相关工具执行以下操作时，使用 `qwen3.5-plus` 模型：

### 1. 笔记创建
- 创建新的 Obsidian 笔记 (`obsidian-cli create`)
- 生成知识节点
- 记录新概念/问题/方案

### 2. 笔记分析
- 分析笔记内容结构
- 识别潜在关联
- 提取关键信息

### 3. 笔记管理
- 建立双链关联
- 整理知识结构
- 优化笔记格式
- 移动/归类笔记

---

## 使用方式

### 方式 1: Obsidian CLI + 模型指定

使用 `obsidian-cli` 创建/管理笔记时，配合模型参数：

```powershell
# 示例：创建笔记（使用 qwen3.5-plus 生成内容）
obsidian-cli create "笔记标题" --content "$(
  openclaw sessions spawn --model "dashscope-coding-plan/qwen3.5-plus" --task "生成关于 XXX 的笔记内容"
)"
```

### 方式 2: 在 Cron 任务中指定

当创建新的笔记相关 Cron 任务时，在 payload 中指定模型：

```json
{
  "payload": {
    "model": "dashscope-coding-plan/qwen3.5-plus",
    "message": "使用 obsidian-cli 整理知识库..."
  }
}
```

### 方式 3: 在脚本中调用

在 PowerShell/Python 脚本中调用 Obsidian 功能时，指定模型参数：

```powershell
# 示例：分析笔记
$analysis = openclaw sessions spawn --model "dashscope-coding-plan/qwen3.5-plus" --task "分析笔记结构..."
obsidian-cli edit "笔记标题" --append "$analysis"
```

### 方式 4: 手动执行

手动执行笔记整理任务时，选择 qwen3.5-plus 模型。

---

## 模型选择原因

**qwen3.5-plus** 适合 Obsidian 笔记任务的原因：
- 擅长结构化输出（Markdown 格式）
- 理解双链笔记概念（[[链接]]）
- 生成清晰的标题和分段
- 适合长文本处理
- 理解知识图谱结构

---

## 不影响现有配置

**重要原则**:
1. ❌ 不修改现有 Cron 任务的模型配置
2. ❌ 不修改现有 Agent 的模型设置
3. ✅ 仅作为新笔记任务的推荐模型
4. ✅ 仅作为运行时工具的选择指导

---

## 现有任务保持不变

以下任务保持原有模型配置，**不受此策略影响**：

| 任务 | 原模型 | 状态 |
|------|--------|------|
| 🏥 健康监控员 | qwen3-coder-plus | ✅ 不变 |
| 📝 配置审计师 | qwen3.5-plus | ✅ 不变 |
| 💾 备份管理员 | qwen3-coder-next | ✅ 不变 |
| 🚑 故障自愈员 | qwen3-coder-next | ✅ 不变 |
| 🧹 日志清理员 | qwen3-coder-next | ✅ 不变 |
| 🛡️ 安全审计员 | glm-5 | ✅ 不变 |
| 📊 运营总监 | glm-5 | ✅ 不变 |
| 📈 每周总结 | glm-5 | ✅ 不变 |
| ... | ... | ✅ 不变 |

---

## 质量要求

使用 qwen3.5-plus 执行笔记任务时，输出应满足：

### 结构要求
- [ ] 有清晰的标题（# 或 ##）
- [ ] 有分段结构（空行分隔）
- [ ] 包含双链 [[链接]]（如适用）

### 内容要求
- [ ] 概述清晰
- [ ] 要点明确
- [ ] 说明详细

### 元数据要求
- [ ] 创建日期
- [ ] 标签
- [ ] 关联笔记

---

## Obsidian 集成示例

### 示例 1: 创建知识笔记

```powershell
# 使用 obsidian-cli 创建笔记，内容通过 qwen3.5-plus 生成
$content = openclaw sessions spawn `
  --model "dashscope-coding-plan/qwen3.5-plus" `
  --task "生成关于'模型调度策略'的笔记，包含概述、核心概念、关联双链"

obsidian-cli create "知识/模型调度策略" --content $content
```

**输出格式**:
```markdown
# 模型调度策略

## 概述
...

## 核心概念
...

## 关联
- [[Obsidian]]
- [[知识管理]]

## 元数据
创建：2026-03-25
标签：#系统 #配置
```

### 示例 2: 整理知识图谱

```powershell
# 分析 knowledge/ 目录，建立双链关联
$analysis = openclaw sessions spawn `
  --model "dashscope-coding-plan/qwen3.5-plus" `
  --task "分析 knowledge/ 目录，识别孤立笔记，建议关联关系"

# 输出报告
$analysis | Out-File "memory/knowledge-analysis.md"
```

### 示例 3: 笔记内容优化

```powershell
# 优化现有笔记的结构和双链
openclaw sessions spawn `
  --model "dashscope-coding-plan/qwen3.5-plus" `
  --task "读取笔记 '知识/Obsidian'，优化结构，添加缺失的双链关联"
```

---

## 总结

| 项目 | 说明 |
|------|------|
| **适用场景** | Obsidian 笔记创建/分析/管理 |
| **推荐模型** | `dashscope-coding-plan/qwen3.5-plus` |
| **现有配置** | 不受影响（零改动） |
| **使用方式** | 运行时指定模型参数 |

---

**版本**: 1.0
**生效**: 2026-03-25
**范围**: 仅 Obsidian 笔记操作
