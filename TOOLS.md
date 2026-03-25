# TOOLS.md - Local Notes

Skills define *how* tools work. This file is for *your* specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:
- Camera names and locations
- SSH hosts and aliases  
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras
- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH
- home-server → 192.168.1.100, user: admin

### TTS
- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

Add whatever helps you do your job. This is your cheat sheet.

## Network

### VPN (Clash Verge)
- System Proxy: `127.0.0.1:7897`
- Type: Clash Verge

## Software Installation

### 默认软件安装路径
- **位置**: `E:\software\`
- **用途**: 专门用于安装各种软件
- **说明**: 所有新软件默认安装到此目录，避免 C 盘空间占用

---

**已安装**:
- Node.js → `E:\software\nodejs\`
- Obsidian → `E:\software\Obsidian\` ✅

**待安装**:
- 其他工具 → `E:\software\<工具名>\`

## Notes & Journal

### Obsidian
- **默认笔记工具**：Obsidian
- **CLI**: `obsidian-cli`
- **用途**: 日记、笔记、知识管理
- **Vault 位置**: `E:\software\Obsidian\vault\`
- **知识库目录**: `E:\software\Obsidian\vault\knowledge\`
  - `知识/` - 通用概念、理论
  - `项目/` - 进行中任务
  - `问题/` - 问题及解决方案
  - `系统设计/` - 架构、规范

> ⚠️ **重要**: 所有笔记必须创建在 `E:\software\Obsidian\vault\` 下，**不是** `D:\OpenClaw\.openclaw\workspace\`！

## Feishu (飞书) 自建应用

**⚠️ 敏感信息 - 注意保护**

- **App ID**: `cli_a92bb7f3923a5ccb`
- **App Secret**: `0i4rX06EKNpiU3FmFH0hNYPJbQ2bpYzN` ⚠️ 建议定期轮换
- **User ID (open_id)**: `ou_a5c4938f3a1fb4354f765ff9c3fcc68c` ✅ 已验证
- **手机号**: +8618768309459

**用途**: 飞书消息通知、机器人集成、下班提醒

**安全建议**:
- 不要在公开场合分享 App Secret
- 定期轮换密钥
- 限制应用权限到最小必要范围

**脚本**:
- `scripts/send-feishu-offwork-reminder.ps1` - 发送下班提醒
- `scripts/query-feishu-users.ps1` - 查询可访问用户列表
