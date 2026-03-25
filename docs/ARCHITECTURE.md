# OpenClaw 架构文档 - 主索引

> 创建时间：2026-03-21  
> 最后更新：2026-03-24 (拆分为模块化文档)  
> 版本：v2.0

---

## 📚 文档结构

本文档体系已拆分为 7 个模块化子笔记，便于维护和查阅：

| 编号 | 文档 | 内容 |
|------|------|------|
| 01 | [[architecture/01-overview]] | 系统架构总览 |
| 02 | [[architecture/02-cron-tasks]] | Cron 任务清单 |
| 03 | [[architecture/03-workflow]] | 任务分发流程 |
| 04 | [[architecture/04-security]] | 安全保障机制 |
| 05 | [[architecture/05-file-structure]] | 关键文件位置 |
| 06 | [[architecture/06-models]] | 模型配置 |
| 07 | [[architecture/07-troubleshooting]] | 故障排查 |

---

## 🚀 快速导航

### 想了解系统整体架构？
→ [[architecture/01-overview]]

### 想查看有哪些定时任务？
→ [[architecture/02-cron-tasks]]

### 想知道任务如何执行？
→ [[architecture/03-workflow]]

### 关心安全问题？
→ [[architecture/04-security]]

### 需要查找文件位置？
→ [[architecture/05-file-structure]]

### 要配置或更换模型？
→ [[architecture/06-models]]

### 遇到故障需要排查？
→ [[architecture/07-troubleshooting]]

---

## 📊 系统统计

- **Cron 任务总数**: 18 个
- **使用模型数**: 7 款
- **日均执行次数**: ~150 次
- **覆盖场景**: 通知、监控、报告、备份、项目、协调、保障
- **安全等级**: 🔒 白名单 + 配置审计 + 灾难恢复

---

## 📁 相关文档

- [GIT-BACKUP-GUIDE](./GIT-BACKUP-GUIDE.md) - Git 备份指南
- [SYSTEM_INFO](./SYSTEM_INFO.md) - 系统信息
- [telegram-commands](./telegram-commands.md) - Telegram 命令

---

*本文档体系由任务协调员每月审查更新*
