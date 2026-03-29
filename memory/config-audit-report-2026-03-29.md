# 配置审计报告 - 2026-03-29

**审计时间**: 2026-03-29 16:25 (Asia/Shanghai)
**审计人**: 📝 配置审计师

---

## 1. openclaw.json 变更检查

| 字段 | 值 |
|------|-----|
| lastTouchedAt | 2026-03-29T04:00:27.587Z |
| lastTouchedVersion | 0.1.9 |
| wizard.lastRunAt | 2026-03-29T04:00:27.561Z |

**结论**: 配置文件在今日 04:00 被访问（每日维护doctor检查），无手动修改。

---

## 2. Cron 任务状态

**状态**: Gateway 超时 (60s)，无法获取任务列表（可能是 Gateway 负载高）
**备注**: 任务列表获取失败，需下次审计复查。

---

## 3. credentials/ 目录检查

| 文件 | 大小 | 最后修改 |
|------|------|---------|
| feishu-pairing.json | 37B | 2026-03-23 |
| telegram-allowFrom.json | 58B | 2026-03-19 |
| telegram-pairing.json | 37B | 2026-03-19 |

**结论**: 凭据文件存在，无异常访问或修改。

---

## 4. Git / 敏感文件检查

**Git 仓库**: ❌ 工作区不是 Git 仓库
**config-backups/.gitignore**: ✅ 已创建（本次）

### 敏感文件状态

| 检查项 | 状态 | 说明 |
|--------|------|------|
| .env (workspace root) | ⚠️ **存在** | 危险：.env 不应出现在 workspace 根目录 |
| .env (parent dir) | ✅ 正确 | .env 在 `D:\OpenClaw\.openclaw\.env` |
| credentials/ | ✅ 正常 | 在正确位置，无异常 |
| openclaw.json (sensitive) | ✅ 正确 | 使用 `${VAR}` 引用环境变量 |

### 🚨 紧急告警：.env 出现在 workspace 根目录

**发现**: `D:\OpenClaw\.openclaw\workspace\.env` 存在（896 字节）
**风险**: 如果 workspace 被上传或分享，API 密钥会泄露
**建议**: 
1. 立即检查该文件内容，确认是否有敏感信息
2. 将其移动到 `D:\OpenClaw\.openclaw\.env`（父目录）
3. 在 workspace 添加 `.env` 到 .gitignore（如有 git）

---

## 5. 备份报告

**本次备份**: `memory/config-backups/openclaw_2026-03-29_162532.json`
**备份数量**: 5 个（含本次）
**最新备份**: jobs-backup-2026-03-29_161856.json (55KB)

---

## 6. 变更差异分析

**自上次审计 (2026-03-27) 以来**:
- openclaw.json: 无手动修改（仅有 wizard doctor 自动更新）
- 无新增敏感配置
- 无意外配置变更

**总体评估**: ✅ 配置稳定，无异常

---

## 7. 安全风险摘要

| 风险 | 级别 | 行动 |
|------|------|------|
| .env 出现在 workspace 根目录 | 🔴 **高** | 需立即检查并迁移 |
| Cron 列表获取超时 | 🟡 中 | 下次审计复查 |
| credentials 文件无异常 | 🟢 低 | 正常 |

---

**下次审计**: 2026-03-30 16:00
