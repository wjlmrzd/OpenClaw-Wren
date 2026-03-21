# Git 历史敏感信息泄露审计报告

**审计时间**: 2026-03-20  
**仓库**: openclaw-workspace  
**提交总数**: 1 (505ed66f5ee51c51fcdc32411558ffe5d3960ad3)

---

## 执行摘要

⚠️ **严重安全警告**: 在 Git 历史中发现多处敏感信息泄露！

- **泄露文件数**: 9 个
- **敏感信息类型**: 4 种
- **泄露次数**: 28 处
- **风险等级**: 🔴 **高危**

---

## 敏感信息统计

| 类型 | 出现次数 | 严重程度 |
|------|---------|---------|
| Telegram Bot Token | 10 | 🔴 高危 |
| Telegram Chat ID | 10 | 🟡 中危 |
| Brave Search API Key | 6 | 🔴 高危 |
| 邮箱地址 | 2 | 🟡 中危 |

---

## 详细泄露清单

### 1. Telegram Bot Token (10 处)

**格式**: `8329757047:AAFxkpIJqkm-8HT1ZFz005tjFDeRRRIisH0`

| 文件路径 | 提交 Hash |
|---------|----------|
| `scripts/openclaw-auto-fix.bat` | 505ed66f5ee51c51fcdc32411558ffe5d3960ad3 |
| `scripts/health-check.bat` | 505ed66f5ee51c51fcdc32411558ffe5d3960ad3 |
| `scripts/health-check-simple.bat` | 505ed66f5ee51c51fcdc32411558ffe5d3960ad3 |
| `scripts/openclaw-health-check.ps1` | 505ed66f5ee51c51fcdc32411558ffe5d3960ad3 |
| `scripts/health-check-v2.ps1` | 505ed66f5ee51c51fcdc32411558ffe5d3960ad3 |
| `scripts/openclaw-auto-fix-v2.bat` | 505ed66f5ee51c51fcdc32411558ffe5d3960ad3 |
| `scripts/secure-config.ps1` | 505ed66f5ee51c51fcdc32411558ffe5d3960ad3 |
| `scripts/init-secure-config.bat` | 505ed66f5ee51c51fcdc32411558ffe5d3960ad3 |
| `scripts/secure-storage.ps1` (不同token) | 505ed66f5ee51c51fcdc32411558ffe5d3960ad3 |
| `scripts/security-audit.bat` (通过环境变量引用) | 505ed66f5ee51c51fcdc32411558ffe5d3960ad3 |

**泄露的 Token 值**:
- `8329757047:AAFxkpIJqkm-8HT1ZFz005tjFDeRRRIisH0` (主要)
- `8329757047:AAEas5LRhvSSGBY6t0zsHzyV8nv_8CZyczA` (secure-storage.ps1)

---

### 2. Telegram Chat ID (10 处)

**格式**: `8542040756` (纯数字)

| 文件路径 | 提交 Hash |
|---------|----------|
| `scripts/openclaw-auto-fix.bat` | 505ed66f5ee51c51fcdc32411558ffe5d3960ad3 |
| `scripts/health-check.bat` | 505ed66f5ee51c51fcdc32411558ffe5d3960ad3 |
| `scripts/health-check-simple.bat` | 505ed66f5ee51ccdc32411558ffe5d3960ad3 |
| `scripts/openclaw-health-check.ps1` | 505ed66f5ee51c51fcdc32411558ffe5d3960ad3 |
| `scripts/health-check-v2.ps1` | 505ed66f5ee51c51fcdc32411558ffe5d3960ad3 |
| `scripts/openclaw-auto-fix-v2.bat` | 505ed66f5ee51c51fcdc32411558ffe5d3960ad3 |
| `scripts/secure-config.ps1` | 505ed66f5ee51c51fcdc32411558ffe5d3960ad3 |
| `scripts/init-secure-config.bat` | 505ed66f5ee51c51fcdc32411558ffe5d3960ad3 |
| `scripts/secure-storage.ps1` | 505ed66f5ee51c51fcdc32411558ffe5d3960ad3 |
| `scripts/security-audit.bat` (通过环境变量引用) | 505ed66f5ee51c51fcdc32411558ffe5d3960ad3 |

---

### 3. Brave Search API Key (6 处)

**格式**: `BSAD9CpbQ_U660f8h-uoXk2cJJ1gdbQ`

| 文件路径 | 提交 Hash |
|---------|----------|
| `scripts/secure-config.ps1` | 505ed66f5ee51c51fcdc32411558ffe5d3960ad3 |
| `scripts/init-secure-config.bat` | 505ed66f5ee51c51fcdc32411558ffe5d3960ad3 |
| `scripts/secure-storage.ps1` | 505ed66f5ee51c51fcdc32411558ffe5d3960ad3 |

---

### 4. 邮箱地址 (2 处)

| 邮箱地址 | 文件路径 | 提交 Hash |
|---------|---------|----------|
| `wjlmrzd@gmail.com` | Git 提交作者信息 | 505ed66f5ee51c51fcdc32411558ffe5d3960ad3 |

---

## 风险分析

### 🔴 高风险项目

1. **Telegram Bot Token 泄露**
   - 攻击者可使用此 token 控制 bot
   - 可发送消息到指定 Chat ID
   - 可获取 bot 关联的所有聊天记录
   - **建议**: 立即在 @BotFather 中撤销并重新生成 token

2. **Brave Search API Key 泄露**
   - 攻击者可使用此 key 进行搜索查询
   - 可能产生费用或达到配额限制
   - **建议**: 在 Brave 账户中撤销并重新生成 API key

### 🟡 中风险项目

3. **Telegram Chat ID 泄露**
   - 攻击者知道你的 Telegram 用户/群组 ID
   - 可发送垃圾消息
   - 可结合 bot token 进行骚扰

4. **邮箱地址泄露**
   - 可能收到垃圾邮件
   - 可用于社工攻击

---

## 修复建议

### 立即行动 (24小时内)

1. **撤销所有泄露的 Token**
   - Telegram Bot: 在 @BotFather 中撤销 `8329757047:AAFxkpIJqkm-8HT1ZFz005tjFDeRRRIisH0`
   - Brave Search: 在 Brave 账户中撤销 `BSAD9CpbQ_U660f8h-uoXk2cJJ1gdbQ`

2. **清理 Git 历史**
   ```bash
   # 使用 BFG Repo-Cleaner 或 git-filter-repo
   git filter-repo --replace-text <(echo '8329757047:AAFxkpIJqkm-8HT1ZFz005tjFDeRRRIisH0==>REMOVED')
   git filter-repo --replace-text <(echo 'BSAD9CpbQ_U660f8h-uoXk2cJJ1gdbQ==>REMOVED')
   ```

3. **强制推送到远程**
   ```bash
   git push origin --force --all
   ```

### 长期措施

1. **使用环境变量**
   - 所有敏感信息应通过环境变量或加密存储加载
   - 已部分实现 (secure-storage.ps1, load-secure-env.bat)

2. **添加 .gitignore**
   - 确保 `.env` 文件被忽略
   - 确保 `secure/` 目录被忽略
   - 已配置 ✅

3. **pre-commit 钩子**
   - 安装 secret 扫描工具 (如 git-secrets, detect-secrets)
   - 在提交前自动检测敏感信息

4. **定期审计**
   - 每月运行一次敏感信息扫描
   - 监控 GitHub 安全警报

---

## 文件状态

| 文件 | 状态 | 说明 |
|------|------|------|
| `scripts/openclaw-auto-fix.bat` | 🔴 包含明文 token | 需要清理历史 |
| `scripts/health-check.bat` | 🔴 包含明文 token | 需要清理历史 |
| `scripts/health-check-simple.bat` | 🔴 包含明文 token | 需要清理历史 |
| `scripts/openclaw-health-check.ps1` | 🔴 包含明文 token | 需要清理历史 |
| `scripts/health-check-v2.ps1` | 🔴 包含明文 token | 需要清理历史 |
| `scripts/openclaw-auto-fix-v2.bat` | 🔴 包含明文 token | 需要清理历史 |
| `scripts/openclaw-auto-fix-v3.bat` | 🟡 使用环境变量 | 较安全 |
| `scripts/openclaw-auto-fix-v4.bat` | 🟡 使用环境变量 | 较安全 |
| `scripts/secure-config.ps1` | 🔴 包含明文 token | 需要清理历史 |
| `scripts/secure-storage.ps1` | 🔴 包含明文 token | 需要清理历史 |
| `scripts/init-secure-config.bat` | 🔴 包含明文 token | 需要清理历史 |
| `scripts/security-audit.bat` | 🟢 使用环境变量 | 安全 |
| `scripts/load-env.bat` | 🟢 无敏感信息 | 安全 |
| `scripts/load-secure-env.bat` | 🟢 无敏感信息 | 安全 |
| `scripts/manual-push.bat` | 🟢 无敏感信息 | 安全 |
| `scripts/openclaw-service-wrapper.bat` | 🟢 无敏感信息 | 安全 |
| `scripts/openclaw-service-wrapper-v2.bat` | 🟢 无敏感信息 | 安全 |
| `.env.example` | 🟢 模板文件 | 安全 |

---

## 结论

当前 Git 仓库存在严重的敏感信息泄露问题。虽然后续版本已经转向使用环境变量和加密存储，但历史提交中仍然包含明文敏感信息。

**必须立即采取行动**:
1. 撤销所有泄露的 API token
2. 清理 Git 历史记录
3. 实施更严格的安全措施防止未来泄露

---

*报告生成时间: 2026-03-20*  
*审计工具: Git Secret Scanner*
