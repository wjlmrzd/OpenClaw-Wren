# Event Hub 事件日志

## 2026-03-24

### 09:45 - 系统初始化
- **来源**: Event Hub 创建
- **动作**: 创建 event-hub-state.json 和 event-log.md
- **状态**: ✅ 完成

### 09:45 - 首次状态检查
- **来源**: 📡 事件协调员
- **数据**: 内存 49.42%, 磁盘 5.4%, Gateway 健康
- **动作**: 更新 event-hub-state.json
- **状态**: ✅ 所有系统正常，无事件触发

---

## 事件类型说明

### 资源事件
- `MEM_HIGH` - 内存使用率 > 85%
- `MEM_CRITICAL` - 内存使用率 > 95%
- `DISK_HIGH` - 磁盘使用率 > 85%
- `DISK_CRITICAL` - 磁盘使用率 > 95%
- `API_QUOTA_HIGH` - API 配额使用 > 80%
- `API_QUOTA_CRITICAL` - API 配额使用 > 95%

### 任务事件
- `TASK_FAILED` - 任务失败 1 次
- `TASK_REPEATED_FAIL` - 任务连续失败≥3 次
- `TASK_TIMEOUT` - 任务执行超时

### Gateway 事件
- `GW_UNHEALTHY` - Gateway 健康检查失败
- `GW_DOWN` - Gateway 无响应
- `GW_RESTARTED` - Gateway 重启完成

### 安全事件
- `SEC_CONFIG_CHANGED` - 配置文件变更
- `SEC_CREDENTIAL_RISK` - 凭证泄露风险

---

## 联动规则

| 触发事件 | 执行动作 | 目标 Agent |
|---------|---------|-----------|
| MEM_HIGH | 触发日志清理 | 🧹 日志清理员 |
| MEM_CRITICAL | 重启 Gateway | 🚑 故障自愈员 |
| TASK_REPEATED_FAIL | 自动修复 | 🚑 故障自愈员 |
| GW_UNHEALTHY | 健康检查 | 🏥 健康监控员 |
| API_QUOTA_HIGH | 延迟非关键任务 | 调度协调员 |
