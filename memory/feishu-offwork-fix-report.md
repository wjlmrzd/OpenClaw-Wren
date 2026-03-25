# 飞书下班提醒 - 问号问题修复报告

## 问题原因

**飞书收到一堆问号** 是因为脚本文件编码错误：
- 原文件：GBK/ANSI 编码（中文 Windows 默认）
- 中文字符在保存/执行时被损坏成乱码

## 已修复内容

### 1. 文件编码 ✅
- 修改为 **UTF-8 with BOM** 编码
- 确保中文字符正确显示

### 2. Emoji 处理 ✅
- 使用 `[char]::ConvertFromUtf32()` 正确处理 emoji
- 避免直接存储 emoji 字符导致的编码问题

### 3. PowerShell 兼容性 ✅
- 移除 `??` 运算符（需要 PS 7+）
- 改用兼容 PS 5.1 的 `if/else` 语法

## 待修复：用户 ID

**当前状态**：脚本使用的用户 ID 无效

| 来源 | 用户 ID | 状态 |
|------|---------|------|
| 脚本默认 | `aafdgb84` | ❓ 未知 |
| TOOLS.md | `ou_a5c4938f3a1fb4354f765ff9c3fcc68c` | ❌ 不存在 |

### 如何获取正确的用户 ID

**方法 1：飞书开放平台**
1. 访问 https://open.feishu.cn/
2. 进入你的应用 → 凭证与基础信息
3. 查看测试用户或使用用户管理 API

**方法 2：使用 API 查询**
```powershell
# 查询当前应用可访问的用户列表
$tokenResp = Invoke-RestMethod -Uri "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" -Method Post -ContentType "application/json" -Body (@{app_id="cli_a92bb7f3923a5ccb"; app_secret="0i4rX06EKNpiU3FmFH0hNYPJbQ2bpYzN"} | ConvertTo-Json)
$token = $tokenResp.tenant_access_token
$headers = @{Authorization="Bearer $token"}
Invoke-RestMethod -Uri "https://open.feishu.cn/open-apis/contact/v3/users?user_id_type=open_id" -Method Get -Headers $headers
```

**方法 3：查看飞书个人设置**
1. 打开飞书桌面客户端
2. 点击头像 → 个人信息
3. 查找用户 ID 或手机号

## 下一步操作

请提供正确的飞书用户 ID，我将更新：
1. `scripts/send-feishu-offwork-reminder.ps1` 中的默认值
2. `TOOLS.md` 中的记录
3. （可选）设置环境变量 `FEISHU_DEFAULT_USER`

## 测试命令

获取正确 ID 后，运行以下命令测试：
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\OpenClaw\.openclaw\workspace\scripts\send-feishu-offwork-reminder.ps1"
```
