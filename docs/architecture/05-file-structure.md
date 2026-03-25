# 05 - 关键文件位置

> 所属：OpenClaw 架构文档体系  
> 最后更新：2026-03-24  
> 相关：[[01-overview]] | [[04-security]]

---

## 目录结构

```
D:\OpenClaw\.openclaw\
├── openclaw.json                    # 主配置文件
├── cron/
│   └── jobs.json                    # Cron 任务配置
├── credentials/
│   └── telegram-allowFrom.json      # Telegram 白名单
├── agents/main/
│   ├── agent/
│   │   └── models.json              # 模型配置
│   └── sessions/
│       └── sessions.json            # 会话状态
└── workspace/
    ├── .gitignore                   # Git 排除规则
    ├── scripts/
    │   ├── log-rotate.ps1           # 日志轮转脚本
    │   ├── config-backup.ps1        # 配置备份脚本
    │   ├── disaster-recovery.ps1    # 灾难恢复脚本
    │   └── gateway-monitor.ps1      # Gateway 监控脚本
    ├── memory/
    │   ├── config-backups/          # 配置备份目录
    │   ├── disaster-recovery/       # 灾难恢复快照
    │   ├── project-todo.md          # 项目待办清单
    │   └── coding-plan-models.md    # 模型配置文档
    └── docs/
        ├── ARCHITECTURE.md          # 架构主索引
        ├── architecture/            # 架构子笔记
        │   ├── 01-overview.md
        │   ├── 02-cron-tasks.md
        │   ├── 03-workflow.md
        │   ├── 04-security.md
        │   ├── 05-file-structure.md
        │   ├── 06-models.md
        │   └── 07-troubleshooting.md
        └── GIT-BACKUP-GUIDE.md      # Git 备份指南
```

---

## 核心配置文件

| 文件 | 用途 | 备份位置 |
|------|------|----------|
| `openclaw.json` | 主配置 | `memory/config-backups/` |
| `cron/jobs.json` | Cron 任务 | `memory/config-backups/` |
| `credentials/` | 凭证 | 不备份 (敏感) |
| `agents/main/agent/models.json` | 模型配置 | 含于 openclaw.json |

---

## 脚本文件

| 脚本 | 用途 | 调用方式 |
|------|------|----------|
| `log-rotate.ps1` | 日志轮转 | 日志清理员 Cron |
| `config-backup.ps1` | 配置备份 | 配置审计师 Cron |
| `disaster-recovery.ps1` | 灾难恢复 | 灾难恢复官 Cron |
| `gateway-monitor.ps1` | Gateway 监控 | Gateway 健康监控 Cron |

---

## 记忆文件

| 文件/目录 | 用途 |
|-----------|------|
| `memory/config-backups/` | 配置备份快照 |
| `memory/disaster-recovery/` | 灾难恢复快照 |
| `memory/project-todo.md` | 项目待办清单 |
| `memory/coding-plan-models.md` | 模型配置文档 |
| `memory/YYYY-MM-DD.md` | 每日工作记录 |
| `MEMORY.md` | 长期记忆 |

---

## 敏感文件 (.gitignore 排除)

```
credentials/
*.env
*.key
*.pem
telegram-allowFrom.json
```

---

## 相关文档

- [[01-overview]] - 系统架构总览
- [[04-security]] - 安全保障机制
- [[GIT-BACKUP-GUIDE]](./GIT-BACKUP-GUIDE.md) - Git 备份指南

---

*返回主索引：[[../ARCHITECTURE]]*
