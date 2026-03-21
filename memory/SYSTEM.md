# 系统参数记录

## 硬件配置

| 组件 | 规格 |
|------|------|
| CPU | Intel Core i5-8300H @ 2.30GHz (4核) |
| 内存 | 16GB DDR4 (2x8GB) |
| GPU | NVIDIA GeForce GTX 1050 Ti (4GB VRAM) |
| 显卡驱动 | 580.88 |

## 系统信息

| 项目 | 值 |
|------|------|
| 操作系统 | Windows 11 Build 22631 |
| Node.js | v25.8.0 |
| 架构 | x64 |

## OpenClaw 环境

| 项目 | 值 |
|------|------|
| 版本 | 2026.1.24-3 (更新可用) |
| Gateway端口 | 18789 |
| Gateway模式 | local (loopback) |
| Dashboard | http://127.0.0.1:18789/ |
| 默认模型 | glm-5 (dashscope-coding-plan) |
| 上下文窗口 | 128k tokens |
| 心跳间隔 | 30分钟 |

## 已配置服务

| 服务 | 状态 |
|------|------|
| GitHub CLI | ✅ 已登录 (wjlmrzd) |
| Telegram | ⚠️ 已配置但未启用 |
| Tailscale | 关闭 |

## 开发环境建议

- **Python**: 建议使用Python 3.10+格式
- **Node.js**: 已安装v25.8.0，建议使用ES模块
- **GPU加速**: GTX 1050 Ti支持CUDA，可用于本地AI推理
- **内存**: 16GB足够运行大多数本地模型

---
*记录时间: 2026-03-21*