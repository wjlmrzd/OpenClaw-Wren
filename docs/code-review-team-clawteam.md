# 4 人代码评审团队 - 使用说明

## 📋 概述

基于 **ClawTeam** 的 4 人代码评审团队，使用顺序工作流：

```
设计师 → 校核员 → 审核员 → 总工
```

每个角色由不同的 AI 模型担任，在独立的 tmux window 和 git worktree 中工作。

| 角色 | 模型 | 职责 |
|------|------|------|
| **设计师** | `qwen3-coder-plus` | 代码架构设计、初版实现 |
| **校核员** | `qwen3.5-plus` | 代码质量检查、风格审查 |
| **审核员** | `minimax-m2.5` ⭐ | 安全性审查、最佳实践 |
| **总工** | `glm-5` | 最终审批、合并决策 |

---

## 🚀 快速开始

### 方式 1：直接告诉我（推荐）

在 Telegram 中对我说：
```
生成一个天气查询插件
```
或
```
创建一个文件批量重命名工具
```

我会自动启动 ClawTeam 团队，你只需要等待最终结果！

### 方式 2：手动启动

```powershell
cd D:\OpenClaw\.openclaw\workspace\scripts
.\launch-code-review.ps1 -Request "生成一个天气查询插件"
```

---

## 📁 目录结构

```
D:\OpenClaw\.openclaw\workspace\code-review\
└── {team-name}/
    ├── design/           # 设计师生成的代码
    ├── review/           # 校核员报告
    │   └── check-report.md
    └── audit/            # 审核员报告
        └── security-report.md

D:\OpenClaw\plugins\      # 最终交付位置
└── {team-name}/
```

---

## 🔄 工作流程

### 1️⃣ 设计师 (Designer)
**模型**: `qwen3-coder-plus`

- 理解用户需求
- 设计代码架构
- 生成初版代码
- 创建 `task.json` 记录设计思路
- 发送消息给校核员

### 2️⃣ 校核员 (Checker)
**模型**: `qwen3.5-plus`

- 等待设计师完成
- 检查代码质量：
  - 代码风格一致性
  - 命名规范
  - 注释完整性
  - 函数/模块复杂度
- 生成 `check-report.md`
- 发送消息给审核员

### 3️⃣ 审核员 (Auditor)
**模型**: `minimax-m2.5`

- 等待校核员完成
- 进行安全性审查：
  - 🔴 安全红线：硬编码密钥、未验证输入、危险系统调用
  - 注入漏洞、权限控制、依赖安全
  - 错误处理、日志记录、资源管理
- 生成 `security-report.md`
- 发送消息给总工

### 4️⃣ 总工 (Chief Engineer)
**模型**: `glm-5`

- 等待所有评审完成
- 收集所有评审意见
- 综合评估并做出决策：
  - ✅ 批准合并
  - ⚠️ 有条件批准
  - ❌ 拒绝（退回设计师）
- 将代码合并到 `D:\OpenClaw\plugins\`
- 发送最终报告到 Telegram

---

## 📊 监控方式

### 看板视图
```powershell
python -m clawteam board show {team-name}
```

### 实时监控
```powershell
python -m clawteam board live {team-name}
```

### Tmux 并排视图（所有 agent 同屏）
```powershell
python -m clawteam board attach {team-name}
```

### Web 面板
```powershell
python -m clawteam board serve --port 8080
# 然后浏览器打开 http://localhost:8080
```

---

## 🔧 常用命令

### 查看任务状态
```powershell
python -m clawteam task list {team-name}
```

### 查看消息
```powershell
python -m clawteam inbox receive {team-name}
```

### 查看团队配置
```powershell
python -m clawteam team status {team-name}
```

### 清理团队
```powershell
python -m clawteam team cleanup {team-name} --force
```

---

## 📝 报告格式

### 校核报告示例
```markdown
# 代码校核报告

## 通过项
- ✅ 代码风格一致
- ✅ 命名规范
- ✅ 注释完整

## 警告项
- ⚠️ 函数 `processData` 过长 (78 行)
- ⚠️ 文件 `utils.js` 超过 500 行

## 建议修改
1. 拆分 `processData` 为多个小函数
2. 将 `utils.js` 拆分为独立模块
```

### 审核报告示例
```markdown
# 安全审核报告

## 安全风险等级：中

## 发现的问题
- 🟡 中等风险：配置文件包含示例 API 密钥
- 🟢 低风险：日志记录过于详细

## 修复建议
1. 使用环境变量存储 API 密钥
2. 生产环境降低日志级别
```

### 最终报告（Telegram）
```
🎉 代码评审完成 - weather-query-plugin

📋 评审流程
- 设计师：✅ 完成
- 校核员：✅ 完成（2 个警告，3 个建议）
- 审核员：✅ 完成（1 个中风险问题，2 个优化建议）
- 总工：✅ 批准合并

📦 交付内容
- 插件位置：D:\OpenClaw\plugins\weather-query-plugin
- 文件清单：
  - index.js
  - config.example.json
  - README.md
  - .env.example

⏱️ 评审耗时：18 分钟
💰 预估成本：¥0.65

📝 后续建议
- 添加单元测试覆盖
- 考虑添加 API 响应缓存
- 建议配置 ESLint 规则
```

---

## 💡 最佳实践

### 1. 清晰的需求描述
需求越具体，设计师生成的代码越准确：
```
✅ 好：生成一个天气查询插件，支持城市名称搜索，使用高德地图 API
❌ 差：做个天气插件
```

### 2. 耐心等待
完整的 4 人评审通常需要 15-30 分钟，取决于代码复杂度。

### 3. 查看中间进度
可以随时使用 `board show` 或 `board live` 查看进度。

### 4. 代码被拒绝怎么办
总工拒绝后，会说明原因。你可以：
- 修改需求重新提交
- 手动修复代码后请求重新评审
- 或忽略建议强制合并（不推荐）

---

## 🔍 故障排除

### 团队启动失败
```powershell
# 检查 ClawTeam 是否正常
python -m clawteam config health

# 检查 openclaw 是否可用
openclaw --version
```

### 某个角色卡住了
```powershell
# 查看任务状态
python -m clawteam task list {team-name}

# 查看该 agent 的消息
python -m clawteam inbox peek {team-name} -a {agent-name}

# 如果确实卡住，可以发送提醒消息
python -m clawteam inbox send {team-name} {agent-name} "请继续工作"
```

### 代码合并失败
检查目标目录是否存在或权限问题：
```powershell
# 手动创建目录
New-Item -ItemType Directory -Force -Path "D:\OpenClaw\plugins\{team-name}"
```

---

## 📚 技术细节

### ClawTeam 模板位置
`D:\OpenClaw\.openclaw\workspace\ClawTeam-OpenClaw\clawteam\templates\code-review-4person.toml`

### 数据存储位置
所有团队数据存储在 `~/.clawteam/`:
- 团队配置：`~/.clawteam/teams/{team-name}/`
- 任务状态：`~/.clawteam/tasks/{team-name}/`
- 消息记录：`~/.clawteam/teams/{team-name}/inboxes/`

### Git Worktree 隔离
每个 agent 有独立的 git worktree 分支：
- `clawteam/{team-name}/designer`
- `clawteam/{team-name}/checker`
- `clawteam/{team-name}/auditor`
- `clawteam/{team-name}/chief-engineer`

总工批准后会合并到主分支。

---

*最后更新：2026-03-24*
*版本：ClawTeam 0.1.1*
