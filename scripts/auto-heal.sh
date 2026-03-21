#!/bin/bash
# OpenClaw 自动修复与安全加固脚本
# 用途: 定期运行安全审计并自动修复问题

set -e

echo "🦞 OpenClaw 自动修复脚本 - $(date)"

# 1. 运行安全审计
echo "📊 执行安全审计..."
openclaw-cn security audit --deep

# 2. 自动修复安全问题
echo "🔧 执行自动修复..."
openclaw-cn security audit --fix

# 3. 运行doctor检查
echo "🏥 执行健康检查..."
openclaw-cn doctor --fix

# 4. 检查网关状态
echo "🌐 检查网关状态..."
openclaw-cn gateway status || openclaw-cn gateway start

# 5. 备份配置
echo "💾 备份配置..."
cp "$OPENCLAW_HOME/.openclaw/openclaw.json" "$OPENCLAW_HOME/.openclaw/openclaw.json.bak.$(date +%Y%m%d%H%M%S)"

echo "✅ 自动修复完成"