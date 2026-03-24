# 稳定性保护机制规格

## 概述

本机制为 OpenClaw 系统提供稳定性保护，防止长时间运行后出现资源竞争和系统雪崩。

## 核心功能

### 1. 限流机制 🚦

**目标**: 同一时间最多只允许一个高负载任务运行

**高负载任务列表**:
| 任务 | ID | 说明 |
|------|----|------|
| 💾 备份管理员 | `c73f1ecf-9f61-47c5-bea1-1c4f322e2ebe` | 全量备份操作 |
| 🧹 日志清理员 | `af025901-6ebc-4541-9698-91c5db9907e6` | 大规模日志清理 |
| 🛡️ 安全审计员 | `53b6edc8-7cc6-4900-ab41-d1abd3e1e15f` | 深度安全扫描 |
| 📝 配置审计师 | `2b564e59-8ed9-4cd8-8345-a9b41e4349bb` | 配置一致性检查 |

**执行策略**:
- 检测是否有高负载任务正在运行
- 若有，新任务进入队列等待
- 若无，立即执行并标记为"运行中"
- 任务完成后自动从队列取出下一个任务

### 2. 任务排队机制 📋

**队列管理**:
- 高负载任务进入 FIFO 队列
- 队列状态持久化到 `memory/task-queue.json`
- 每次稳定性检查时处理队列

**队列优先级**:
1. 手动触发的任务（最高优先级）
2. 定时任务（正常优先级）
3. 重试任务（根据错误次数调整）

### 3. Token 使用预测 📊

**预测算法**:
- 基于过去 7 天的 Token 使用历史
- 计算过去 6 小时的平均使用量
- 预测未来 6 小时的使用趋势

**阈值管理**:
| 预测使用量 | 动作 |
|-----------|------|
| > 80% 配额 | 进入降载模式 |
| > 90% 配额 | 停止低优先级任务 |
| 趋势上升 | 记录告警 |

**配额假设**: 每日 1,000,000 tokens（可配置）

### 4. 每日轻量维护 🔧

**执行时间**: 每天 03:30（低峰期）

**维护内容**:
1. **清理缓存**
   - OpenClaw 缓存（>3 天）
   - PowerShell 临时文件（>1 天）
   - 工作区临时文件（>1 天）

2. **重新加载配置**
   - 验证配置有效性
   - 应用配置变更

3. **Gateway 轻量重启**（条件触发）
   - Gateway 响应异常时
   - 内存使用率 > 90% 时
   - 连续失败任务 ≥ 3 个时

**维护日志**: 记录到 `memory/daily-maintenance-log.md`

### 5. 防止自愈风暴 🛡️

**问题**: auto_healer 在短时间内重复执行修复，导致系统压力上升

**防护策略**:
- 时间窗口：10 分钟
- 最大修复次数：3 次
- 超限后暂停自愈，等待窗口重置

**状态追踪**:
```json
{
  "healerStormProtection": {
    "windowStart": "2026-03-24T10:00:00Z",
    "repairCount": 2,
    "maxRepairsPerWindow": 3,
    "windowMinutes": 10
  }
}
```

**修复动作计数**:
- 任务重试 ✅
- 模型切换 ✅
- Gateway 重启 ✅

## 新增 Agent

### 🛡️ 稳定性守护员

**ID**: `stability-guardian` (待分配)

**频率**: 每 10 分钟

**职责**:
1. 检查高负载任务运行状态
2. 处理任务队列
3. 预测 Token 使用
4. 检查自愈风暴保护状态
5. 记录稳定性指标

**脚本**: `scripts/stability-protector.ps1`

### 🔧 每日维护员

**ID**: `daily-maintainer` (待分配)

**频率**: 每天 03:30

**职责**:
1. 清理缓存和临时文件
2. 重新加载配置
3. 检查 Gateway 健康
4. 执行轻量重启（如需要）
5. 记录维护日志

**脚本**: `scripts/daily-light-maintenance.ps1`

## 状态文件

### memory/stability-state.json
```json
{
  "currentMode": "normal",
  "activeHighLoadTask": null,
  "taskQueue": [],
  "lastMaintenance": "2026-03-24T03:30:00Z",
  "healerStormProtection": {
    "windowStart": "2026-03-24T10:00:00Z",
    "repairCount": 0,
    "maxRepairsPerWindow": 3,
    "windowMinutes": 10
  },
  "tokenPrediction": {
    "lastCheck": "2026-03-24T10:00:00Z",
    "predicted6h": 500000,
    "trend": "stable"
  }
}
```

### memory/token-usage-history.json
```json
{
  "history": [
    {"timestamp": "2026-03-24T10:00:00Z", "tokens": 50000, "hour": 10},
    ...
  ],
  "lastUpdate": "2026-03-24T10:00:00Z"
}
```

## 与其他组件的联动

### 与系统模式控制器
- Token 预测超限 → 建议进入降载模式
- 高负载任务排队 → 记录系统负载状态

### 与故障自愈员
- 自愈风暴保护 → 限制修复频率
- 修复动作计数 → 共享状态文件

### 与事件协调员
- 稳定性事件 → 发送 STABILITY_WARNING/STABILITY_CRITICAL
- 维护完成 → 发送 MAINTENANCE_COMPLETE

## 监控指标

| 指标 | 阈值 | 告警级别 |
|------|------|---------|
| 高负载任务队列长度 | > 3 | 🟡 警告 |
| Token 预测 (6h) | > 80% | 🟡 警告 |
| Token 预测 (6h) | > 90% | 🔴 紧急 |
| 自愈修复次数 (10min) | ≥ 3 | 🟡 警告 |
| 距离上次维护时间 | > 48h | 🟡 警告 |

## 故障排除

### 高负载任务卡住
1. 检查 `memory/stability-state.json` 中的 `activeHighLoadTask`
2. 手动清除卡住的任务状态
3. 重启稳定性守护员

### Token 预测不准确
1. 检查 `memory/token-usage-history.json` 数据完整性
2. 确认配额配置是否正确
3. 调整预测算法参数

### 自愈风暴保护误触发
1. 检查时间窗口配置是否合理
2. 评估最大修复次数是否需要调整
3. 查看 `memory/incident-log.md` 了解触发原因

## 版本历史

- **v1.0** (2026-03-24): 初始实现
  - 限流机制
  - 任务排队
  - Token 预测
  - 每日维护
  - 自愈风暴防护
