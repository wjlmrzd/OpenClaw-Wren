# 配置审计报告 - 2026-04-03 20:20

## 变更检测

### openclaw.json
- **lastTouchedAt**: 2026-04-02T14:35:13.901Z → 2026-04-03T10:20:00.000Z ✅ 已更新
- **重大变更**: 模型 contextWindow/maxTokens 全面更正

| 模型 | 旧值 (错误) | 新值 (正确) |
|------|------------|------------|
| minimax-2.7 | 128K/8K | 204K/131K |
| qwen3.5-plus | 128K/8K | 262K/32K |
| qwen3-coder-plus | 128K/8K | 998K/65K |
| qwen3-coder-next | 128K/8K | 262K/65K |
| glm-5 | 128K/8K | 200K/16K |
| glm-4.7 | 128K/8K | 200K/128K |
| kimi-k2.5 | 128K/8K | 262K/32K |
| minimax-m2.5 | 128K/8K | 196K/65K |

### graph-memory 配置
- compactTurnCount: 5 → 10
- 新增 llm 配置 (glm-5)
- 新增 embedding 配置 (text-embedding-v2)

### lossless-claw 配置
- contextThreshold: 0.6 → 0.8

### cron/jobs.json
- 活跃任务数: 32 (与上次一致)

## 安全检查

| 项目 | 状态 | 说明 |
|------|------|------|
| credentials 目录 | ✅ | 3 个文件，未泄露 |
| git 状态 | ✅ | 无敏感文件提交风险 |
| .env 配置 | ✅ | 通过环境变量注入 |

### credentials 目录文件
- feishu-pairing.json
- telegram-allowFrom.json
- telegram-pairing.json

## 备份快照

**位置**: `memory/config-backups/20260403-2020/`
- openclaw.json ✅
- jobs.json ✅

## 审计结论

- 🟢 **配置健康** - 无安全风险
- 🔧 **重大变更已记录** - 模型规格更正
- ✅ **备份完成**

---
*审计师: 📝 配置审计师 (cron:2b564e59)*
*执行时间: 2026-04-03 20:20*