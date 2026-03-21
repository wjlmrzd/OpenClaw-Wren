# Git 远程备份配置指南

## 目的
将 OpenClaw workspace 备份到私有 Git 仓库，实现异地容灾。

## 步骤

### 1. 创建私有仓库
在 GitHub / Gitee 创建**私有仓库**：
- 仓库名：`openclaw-workspace-private`
- 可见性：**Private**（重要！）
- 初始化：不要添加 README/.gitignore

### 2. 配置远程仓库
```powershell
cd D:\OpenClaw\.openclaw\workspace

# 添加远程仓库（替换为你的仓库地址）
git remote add origin https://github.com/YOUR_USERNAME/openclaw-workspace-private.git

# 验证
git remote -v
```

### 3. 首次推送
```powershell
# 添加所有文件
git add .

# 提交
git commit -m "Initial backup: OpenClaw workspace"

# 推送
git push -u origin master
```

### 4. 配置自动备份
Workspace 备份 Cron 任务已配置（每天 23:00），会自动执行：
```powershell
git add .
git commit -m "Auto-backup: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
git push origin master
```

## ⚠️ 安全注意事项

### 必须排除的敏感文件
确保 `.gitignore` 包含以下内容：

```gitignore
# 敏感凭据
.env
*.key
*.pem
credentials/
telegram-bot-token.txt

# 包含 API Key 的配置文件
openclaw.json
agents/main/agent/auth-profiles.json

# 会话数据（可能含私人对话）
sessions/*.jsonl
sessions/sessions.json

# 日志文件
logs/*.log
*.gz

# 临时文件
*.tmp
*.bak
```

### 推荐做法
1. **使用私有仓库** - 绝不公开
2. **定期轮换 Token** - 如泄露立即更新
3. **加密敏感配置** - 使用环境变量或加密工具
4. **审查提交内容** - 推送前检查 `git status`

## 恢复流程

如需要恢复：
```powershell
# 克隆仓库
git clone https://github.com/YOUR_USERNAME/openclaw-workspace-private.git

# 复制配置
Copy-Item workspace\* D:\OpenClaw\.openclaw\workspace\ -Recurse -Force

# 重启 OpenClaw
openclaw gateway restart
```

## 替代方案

### 本地备份（无远程仓库）
- 配置已创建：每天 23:00 本地 git commit
- 优点：安全、快速
- 缺点：无异地容灾

### 加密云备份
- 使用 Cryptomator / VeraCrypt 加密后上传
- 云存储：OneDrive / Google Drive / iCloud
- 优点：异地 + 加密
- 缺点：需要额外配置
