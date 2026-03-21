# OpenClaw 自动修复与安全加固方案

## 方案概述

本方案提供多层次的安全保障和自动修复机制，确保OpenClaw网关稳定运行。

---

## 📋 方案选项

### 方案A: 基础安全加固 (推荐入门)

**功能:**
- 定期安全审计
- 自动修复权限问题
- 配置自动备份

**配置:**
```yaml
# 添加到 crontab (Linux) 或 Task Scheduler (Windows)
# 每6小时运行一次
0 */6 * * * /path/to/auto-heal.sh
```

**优点:** 轻量级，资源消耗低
**缺点:** 仅修复已知问题，无预防机制

---

### 方案B: 网关守护 + 自动重启 (推荐生产)

**功能:**
- 方案A的所有功能
- 网关进程监控
- 自动重启失败服务
- 配置变更自动验证

**配置:**
```yaml
# 使用 systemd (Linux)
[Unit]
Description=OpenClaw Gateway Watchdog
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/openclaw-cn gateway --watchdog
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target

# Windows Task Scheduler
# 触发器: 每5分钟
# 操作: powershell -File scripts/auto-heal.ps1
```

**优点:** 高可用性，自动恢复
**缺点:** 需要更多系统资源

---

### 方案C: 完整安全套件 (推荐高安全场景)

**功能:**
- 方案B的所有功能
- 实时入侵检测
- 敏感操作审计日志
- 外部密钥管理支持
- 配置漂移检测

**配置:**
```yaml
# openclaw.json 增强
{
  "hooks": {
    "internal": {
      "enabled": true,
      "entries": {
        "session-memory": { "enabled": true },
        "security-audit": { "enabled": true },
        "config-drift-detector": { "enabled": true }
      }
    }
  },
  "security": {
    "auditLog": true,
    "auditLogPath": "$OPENCLAW_HOME/.openclaw/logs/audit.log",
    "alertOnSuspiciousActivity": true,
    "externalSecrets": {
      "enabled": true,
      "provider": "env"  # 或 "1password", "vault"
    }
  },
  "gateway": {
    "autoRestart": {
      "enabled": true,
      "maxRestarts": 3,
      "cooldownMinutes": 5
    },
    "healthCheck": {
      "intervalSeconds": 30,
      "timeoutSeconds": 10,
      "onFailure": "restart"
    }
  }
}
```

**优点:** 最高安全级别，全面审计
**缺点:** 配置复杂，需要专业知识

---

## 🚀 快速启动

### 选择方案A (基础)
```bash
# 1. 下载脚本
curl -o auto-heal.sh https://your-server/auto-heal.sh
chmod +x auto-heal.sh

# 2. 添加到 crontab
(crontab -l 2>/dev/null; echo "0 */6 * * * /path/to/auto-heal.sh") | crontab -

# 3. 验证
./auto-heal.sh
```

### 选择方案B (推荐)
```bash
# Windows: 打开 Task Scheduler
# 创建基本任务:
# - 名称: OpenClaw Auto-Heal
# - 触发器: 每天，每6小时重复
# - 操作: 启动程序
#   - 程序: powershell.exe
#   - 参数: -ExecutionPolicy Bypass -File "D:\OpenClaw\.openclaw\workspace\scripts\auto-heal.ps1"
```

### 选择方案C (高级)
需要手动编辑配置文件并启用安全hook。

---

## ⚙️ Cron 定时任务配置

建议的定时任务:

| 任务 | 频率 | 命令 |
|------|------|------|
| 安全审计 | 每6小时 | `openclaw-cn security audit --deep` |
| 自动修复 | 每6小时 | `openclaw-cn security audit --fix` |
| 健康检查 | 每30分钟 | `openclaw-cn doctor --fix` |
| 配置备份 | 每天 | 复制 openclaw.json |

---

## 📝 敏感信息管理

敏感信息已保存到 `.env` 文件:
- `BRAVE_SEARCH_API_KEY` - Brave搜索API密钥
- `TELEGRAM_BOT_TOKEN` - Telegram机器人令牌

**重要:** `.env` 文件已添加到 `.gitignore`，不会被提交到仓库。

---

## 下一步

请选择您想要的方案:
1. **方案A** - 基础安全加固
2. **方案B** - 网关守护 + 自动重启 (推荐)
3. **方案C** - 完整安全套件

我将根据您的选择进行配置。

---
*创建时间: 2026-03-21*