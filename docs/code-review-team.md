# 代码评审团队 - 使用说明

## 📋 概述

4 人代码评审团队由 4 个独立的 cron 任务组成，每个角色由不同的 AI 模型担任：

| 角色 | 模型 | 职责 |
|------|------|------|
| **设计师** | `qwen3-coder-plus` | 代码架构设计、初版实现 |
| **校核员** | `qwen3.5-plus` | 代码质量检查、风格审查 |
| **审核员** | `minimax-m2.5` | 安全性、最佳实践审查 |
| **总工** | `glm-5` | 最终审批、合并决策 |

## 🚀 快速开始

### 方式 1：直接告诉我（推荐）

在 Telegram 中对我说：
```
生成一个 XX 插件
```
或
```
创建 XX 功能的代码
```

我会自动启动代码评审流程，你只需要等待最终结果。

### 方式 2：手动触发

```powershell
# 启动新的代码评审任务
cd D:\OpenClaw\.openclaw\workspace\scripts
.\code-review-coordinator.ps1 start -Request "生成一个天气查询插件"

# 查看任务状态
.\code-review-coordinator.ps1 status -TaskId <task-id>

# 列出所有任务
.\code-review-coordinator.ps1 list
```

## 📁 目录结构

```
D:\OpenClaw\.openclaw\workspace\code-review\
└── {task-id}/
    ├── task.json              # 任务描述
    ├── design/                # 设计师生成的代码
    ├── review/                # 校核员报告
    │   └── check-report.md
    ├── audit/                 # 审核员报告
    │   └── security-report.md
    ├── design.done            # 设计完成标记
    ├── check.done             # 校核完成标记
    └── audit.done             # 审核完成标记

D:\OpenClaw\plugins\           # 最终交付位置
└── {plugin-name}/
```

## 🔄 工作流程

```
用户请求
    ↓
[设计师] → 生成代码 → design/
    ↓ (创建 design.done)
[校核员] → 质量检查 → review/check-report.md
    ↓ (创建 check.done)
[审核员] → 安全审查 → audit/security-report.md
    ↓ (创建 audit.done)
[总工] → 最终审批 → 合并到 plugins/
    ↓
发送最终报告到 Telegram
```

## 📊 任务状态

每个任务有以下状态：
- `started` - 任务已启动
- `designing` - 设计师工作中
- `checking` - 校核员工作中
- `auditing` - 审核员工作中
- `approving` - 总工审批中
- `completed` - 完成并合并
- `rejected` - 被拒绝（需重新设计）

## ⚙️ Cron 任务 ID

如需手动触发特定角色：

| 角色 | Cron Job ID |
|------|-------------|
| 设计师 | `a0ea64d4-4118-43e3-9cf3-25dc84909038` |
| 校核员 | `d10df21e-7512-4751-93c6-0901e51cf632` |
| 审核员 | `b0006971-6353-49e6-9892-354ec527651d` |
| 总工 | `41af46d0-9f18-4f60-b31a-8f5ca02ffe9b` |

```powershell
# 手动触发设计师
openclaw cron run --job-id a0ea64d4-4118-43e3-9cf3-25dc84909038
```

## 📝 报告格式

### 校核报告 (check-report.md)
```markdown
# 代码校核报告

## 通过项
- ✅ 代码风格一致
- ✅ 命名规范

## 警告项
- ⚠️ 函数过长 (line 45-120)

## 建议修改
- 建议拆分 XX 函数
```

### 审核报告 (security-report.md)
```markdown
# 安全审核报告

## 安全风险等级：低

## 发现的问题
- ⚠️ 中等：未验证用户输入
- ✅ 低风险：日志记录过多

## 修复建议
1. 添加输入验证
2. 减少调试日志
```

### 最终报告 (Telegram)
```
🎉 代码评审完成 - 天气查询插件

📋 评审流程
- 设计师：✅ 完成
- 校核员：✅ 完成（2 个警告，3 个建议）
- 审核员：✅ 完成（1 个安全问题，2 个优化建议）
- 总工：✅ 批准合并

📦 交付内容
- 插件位置：D:\OpenClaw\plugins\weather-query
- 文件清单：
  - index.js
  - config.json
  - README.md

⏱️ 评审耗时：15 分钟
💰 预估成本：¥0.50

📝 后续建议
- 添加单元测试
- 考虑缓存优化
```

## 🔧 故障排除

### 任务卡住了怎么办？

1. 检查当前状态：
```powershell
.\code-review-coordinator.ps1 status -TaskId <task-id>
```

2. 手动触发下一阶段：
```powershell
# 如果设计师完成了但校核员没启动
.\code-review-coordinator.ps1 trigger-checker -TaskId <task-id>
```

### 代码被拒绝了怎么办？

总工拒绝后，任务会标记为 `rejected`。你可以：
1. 查看拒绝原因（在总工报告中）
2. 修改需求重新提交
3. 或手动修复代码后请求重新评审

## 💡 最佳实践

1. **清晰的需求描述**：需求越具体，设计师生成的代码越准确
2. **耐心等待**：完整的 4 人评审可能需要 10-30 分钟
3. **查看中间报告**：可以随时查看校核/审核报告了解进度
4. **反馈改进**：如果对评审结果不满意，告诉我优化流程

---

*最后更新：2026-03-24*
