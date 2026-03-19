# OpenClaw Workspace

自动化的 OpenClaw 配置管理和监控系统

## 功能概览

### 1. 自动健康检查 (每12小时)
- **任务名**: `OpenClaw-Health-Check`
- **脚本**: `scripts/health-check-simple.bat`
- **功能**:
  - 检查网关运行状态
  - 监控磁盘空间和内存使用
  - 安全审计（配置验证、令牌检查）
  - 发送 Telegram 报告

### 2. 自动修复机制
- **任务名**: `OpenClaw-Service-Wrapper` (开机启动)
- **脚本**: `scripts/openclaw-service-wrapper.bat`
- **功能**:
  - 持续监控网关状态
  - 检测到崩溃时自动重启
  - 运行诊断和修复脚本
  - 自动同步到 GitHub

### 3. GitHub 自动备份
- **工作流**: `.github/workflows/auto-backup.yml`
- **触发条件**:
  - 每6小时自动运行
  - 每次推送时
  - 手动触发

## 手动操作命令

```batch
:: 运行自动修复
scripts\openclaw-auto-fix.bat

:: 查看日志
type %USERPROFILE%\.openclaw\logs\auto-fix.log
type %USERPROFILE%\.openclaw\logs\health-check.log

:: 检查定时任务
schtasks /Query /TN "OpenClaw-Health-Check"
schtasks /Query /TN "OpenClaw-Service-Wrapper"

:: 手动触发 GitHub 同步
cd /d D:\OpenClaw\.openclaw\workspace
git add .
git commit -m "Manual backup"
git push origin master
```

## 仓库地址
https://github.com/wjlmrzd/openclaw-workspace

## 系统信息
- OS: Windows 11
- Node: v25.8.0
- OpenClaw: 0.1.8-fix.3
- Model: kimi-k2.5
