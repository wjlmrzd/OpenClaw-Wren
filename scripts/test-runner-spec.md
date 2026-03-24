# 🧪 回归测试员 (Test Runner)

**职责：** 代码/配置变更后自动执行测试，防止破坏性变更

---

## 核心功能

### 1. 变更检测

**监控目标：**
- `openclaw.json` - Gateway 配置
- `cron/jobs.json` - Cron 任务配置
- `skills/` - 技能脚本
- `scripts/` - 辅助脚本
- `agents/` - Agent 配置

**检测方式：**
- 文件哈希值对比
- Git 提交检测（如使用 Git）
- 文件修改时间监控

### 2. 测试类型

#### A. 配置验证测试

```yaml
test: config_syntax
description: 验证 JSON/YAML 语法正确
files:
  - openclaw.json
  - cron/jobs.json
validation:
  - json.parse()
  - schema.validate()
```

```yaml
test: model_validation
description: 验证模型名称有效
files:
  - cron/jobs.json
checks:
  - model in ALLOWED_MODELS
  - model_prefix in ["dashscope-coding-plan/", ...]
```

```yaml
test: schedule_validation
description: 验证 cron 表达式有效
files:
  - cron/jobs.json
checks:
  - cron_expr.parse()
  - no_collision_at_same_minute (警告级别)
```

#### B. 功能测试

```yaml
test: gateway_health
description: Gateway 启动后健康检查
trigger: openclaw.json changed
checks:
  - GET /status returns 200
  - response_time < 5s
```

```yaml
test: cron_job_validation
description: 验证 Cron 任务可执行
trigger: cron/jobs.json changed
checks:
  - job.enabled → verify model exists
  - job.schedule → verify next_run computable
  - job.payload → verify message not empty
```

#### C. 脚本测试

```yaml
test: powershell_syntax
description: 验证 PS1 脚本语法
files:
  - scripts/*.ps1
command: pwsh -NoProfile -Command "Invoke-Expression (Get-Content '{file}')"
expect: exit_code == 0
```

```yaml
test: script_dry_run
description: 脚本空跑测试
files:
  - scripts/auto-healer.ps1
  - scripts/event-hub-tools.ps1
command: pwsh -File '{file}' -DryRun
expect: exit_code == 0
```

### 3. 测试流程

```
检测到变更
    ↓
备份当前配置
    ↓
执行语法测试
    ↓
执行功能测试
    ↓
生成测试报告
    ↓
有失败 → 告警 + 建议回滚
全部通过 → 静默/通知
```

---

## 触发模式

### 模式 1: 主动监控（默认）

**频率：** 每 10 分钟检查一次

```yaml
schedule: "*/10 * * * *"
action:
  - compute_file_hashes()
  - compare_with_previous()
  - if_changed → run_tests()
```

### 模式 2: 被动触发

**触发条件：**
- 用户手动运行：`openclaw cron run --id test-runner`
- Git webhook 触发（高级）
- 其他 Agent 通知（如配置审计师）

### 模式 3: 前置测试（高级）

**适用场景：** 重要配置变更前

```yaml
pre_commit_test:
  enabled: true
  block_on_failure: true
  notify: telegram
```

---

## 测试用例库

### 核心测试（必须通过）

| ID | 测试名 | 触发条件 | 严重性 |
|----|--------|---------|--------|
| T001 | JSON 语法验证 | 所有 JSON 文件 | 🔴 阻断 |
| T002 | 模型名称验证 | cron/jobs.json | 🔴 阻断 |
| T003 | Cron 表达式验证 | cron/jobs.json | 🔴 阻断 |
| T004 | Gateway 健康检查 | openclaw.json | 🔴 阻断 |
| T005 | PowerShell 语法 | scripts/*.ps1 | ⚠️ 警告 |

### 扩展测试（可选）

| ID | 测试名 | 触发条件 | 严重性 |
|----|--------|---------|--------|
| T101 | 任务撞车检测 | cron/jobs.json | 🟡 注意 |
| T102 | API 配额预估 | cron/jobs.json | 🟡 注意 |
| T103 | 超时配置合理性 | cron/jobs.json | 🟡 注意 |
| T104 | 依赖关系验证 | cron/jobs.json | 🟡 注意 |

---

## 输出格式

### 测试通过

```
🧪 回归测试报告 - HH:mm

✅ 全部通过 (X/Y 测试)

📊 测试摘要:
- 配置验证：✅ 5/5
- 功能测试：✅ 3/3
- 脚本测试：✅ 2/2

📝 变更内容:
- cron/jobs.json: 修改 1 个任务调度
- scripts/auto-healer.ps1: 新增功能
```

### 测试失败

```
🧪 回归测试报告 - HH:mm

❌ 发现失败 (X/Y 测试)

🔴 阻断性问题:
1. T002 - 模型名称验证失败
   文件：cron/jobs.json
   任务：💼 项目顾问
   错误：Unknown model: anthropic/qwen3.5-plus
   建议：使用 dashscope-coding-plan/qwen3.5-plus

🔧 建议动作:
1. 回滚配置：`git checkout cron/jobs.json`
2. 修复模型名称
3. 重新运行测试

📋 测试详情：memory/test-reports/YYYY-MM-DD-HHmmss.md
```

---

## 状态文件

### memory/test-runner-state.json

```json
{
  "lastCheck": 1774316400000,
  "fileHashes": {
    "openclaw.json": "abc123...",
    "cron/jobs.json": "def456...",
    "scripts/auto-healer.ps1": "ghi789..."
  },
  "lastTestRun": {
    "timestamp": 1774316400000,
    "trigger": "file_change",
    "changedFiles": ["cron/jobs.json"],
    "results": {
      "total": 10,
      "passed": 9,
      "failed": 1,
      "warnings": 0
    },
    "reportPath": "memory/test-reports/2026-03-24-094500.md"
  },
  "statistics": {
    "totalRuns": 15,
    "passRate": 0.93,
    "commonFailures": ["model_validation"]
  }
}
```

---

## 联动机制

### 与配置审计师联动

```
配置审计师检测到变更
    ↓
通知回归测试员
    ↓
执行测试
    ↓
失败 → 通知配置审计师回滚
通过 → 记录审计日志
```

### 与故障自愈员联动

```
回归测试发现模型错误
    ↓
通知故障自愈员
    ↓
自动修复配置
    ↓
重新运行测试验证
```

---

## 实施步骤

1. **创建测试框架**
   - 基础测试函数库
   - 报告生成器
   - 状态管理器

2. **添加 Test Runner Agent**
   - 每 10 分钟检查变更
   - 执行核心测试

3. **创建测试报告目录**
   - memory/test-reports/
   - 存储历史测试报告

4. **集成到工作流**
   - 配置变更后自动触发
   - 失败时阻止部署

---

## 测试示例

### 示例 1: 模型配置错误检测

```powershell
# 测试：模型名称验证
$jobs = Get-Content cron/jobs.json | ConvertFrom-Json
$allowedModels = @(
    "dashscope-coding-plan/qwen3.5-plus",
    "dashscope-coding-plan/glm-5",
    "dashscope-coding-plan/kimi-k2.5"
)

foreach ($job in $jobs.jobs) {
    if ($job.payload.model -and $allowedModels -notcontains $job.payload.model) {
        Write-Error "任务 '$($job.name)' 使用无效模型：$($job.payload.model)"
        $testFailed = $true
    }
}
```

### 示例 2: Gateway 健康检查

```powershell
# 测试：Gateway 响应
try {
    $response = Invoke-WebRequest -Uri "http://127.0.0.1:18789/status" -TimeoutSec 5
    if ($response.StatusCode -ne 200) {
        throw "Gateway 返回状态码：$($response.StatusCode)"
    }
    Write-Host "✅ Gateway 健康检查通过"
} catch {
    Write-Error "❌ Gateway 健康检查失败：$_"
}
```

---

## 成功标准

- [ ] 配置变更后 10 分钟内自动检测
- [ ] 核心测试 100% 覆盖
- [ ] 失败测试提供明确修复建议
- [ ] 测试报告可追溯
- [ ] 与 Auto-Healer 联动自动修复
