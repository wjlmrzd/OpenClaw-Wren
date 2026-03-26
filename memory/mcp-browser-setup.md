# MCP 浏览器控制配置指南

**创建时间**: 2026-03-26  
**状态**: 配置中

---

## 已完成的步骤

### 1. ✅ 安装 mcporter
```bash
npm install -g mcporter
```

### 2. ✅ 添加 MCP 服务器配置

**配置文件**: `config/mcporter.json`

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx -y @microsoft/playwright-mcp"
    },
    "puppeteer": {
      "command": "npx -y @modelcontextprotocol/server-puppeteer"
    }
  }
}
```

---

## 遇到的问题

### 问题 1: Playwright MCP 连接失败
- **错误**: `MCP error -32000: Connection closed`
- **原因**: 可能是网络问题或依赖未安装

### 问题 2: Puppeteer MCP 超时
- **错误**: `timed out after 30000ms`
- **原因**: npx 下载包需要时间，超过 30 秒超时

---

## 解决方案

### 方案 A: 本地安装依赖（推荐）

先本地安装 Playwright/Puppeteer，避免 npx 下载超时：

```bash
# 安装 Playwright
npm install -g @microsoft/playwright-mcp

# 或安装 Puppeteer
npm install -g @modelcontextprotocol/server-puppeteer
```

然后修改配置使用全局命令：

```json
{
  "mcpServers": {
    "playwright": {
      "command": "playwright-mcp"
    }
  }
}
```

### 方案 B: 使用 HTTP 模式（如有）

如果 MCP 服务器支持 HTTP 模式，可以：

```bash
mcporter config add browser-http --url "http://localhost:3000/mcp"
```

### 方案 C: 继续使用 OpenClaw 内置 browser 工具

如果 MCP 配置复杂，可以继续使用现有的 OpenClaw browser 工具：

```json
{
  "browser": {
    "controlToken": "${GATEWAY_CONTROL_TOKEN}",
    "profile": "chrome"
  }
}
```

---

## 下一步

需要用户选择：

1. **继续配置 MCP** - 我尝试本地安装依赖
2. **使用现有方式** - OpenClaw 内置 browser 工具已可用

---

## 参考链接

- [Playwright MCP GitHub](https://github.com/microsoft/playwright-mcp)
- [Puppeteer MCP](https://www.pulsemcp.com/servers/modelcontextprotocol-puppeteer)
- [MC Porter 文档](http://mcporter.dev)
