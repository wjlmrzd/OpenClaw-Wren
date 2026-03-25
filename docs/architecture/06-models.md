# 06 - 模型配置

> 所属：OpenClaw 架构文档体系  
> 最后更新：2026-03-24  
> 相关：[[01-overview]] | [[02-cron-tasks]]

---

## 已配置模型 (7 款)

### 通义千问 (阿里自研)

| 模型 | 用途 | 特点 |
|-----|------|------|
| `qwen3.5-plus` | 通用对话、综合报告 | 旗舰模型，3970 亿参数 |
| `qwen3-coder-plus` | 代码开发、系统监控 | 编程增强版 |
| `qwen3-coder-next` | 代码生成、备份任务 | 编程专用 |

### 智谱 GLM

| 模型 | 用途 | 特点 |
|-----|------|------|
| `glm-5` | 长文档、安全审计 | 智谱旗舰，长任务领先 |
| `glm-4.7` | 备用 | GLM 4.7 版本 |

### 月之暗面 Kimi

| 模型 | 用途 | 特点 |
|-----|------|------|
| `kimi-k2.5` | 邮件监控、多模态 | 多模态和编程能力 |

### MiniMax

| 模型 | 用途 | 特点 |
|-----|------|------|
| `minimax-m2.5` | 日程、办公场景 | Agent 场景优化 |

---

## 默认配置

```json
{
  "models": {
    "mode": "merge",
    "providers": [
      {
        "id": "dashscope-coding-plan",
        "name": "阿里云百炼 Coding Plan",
        "models": [
          {"id": "qwen3.5-plus", "name": "qwen3.5-plus"},
          {"id": "qwen3-coder-plus", "name": "qwen3-coder-plus"},
          {"id": "qwen3-coder-next", "name": "qwen3-coder-next"},
          {"id": "glm-5", "name": "glm-5"},
          {"id": "glm-4.7", "name": "glm-4.7"},
          {"id": "kimi-k2.5", "name": "kimi-k2.5"},
          {"id": "minimax-m2.5", "name": "minimax-m2.5"}
        ]
      }
    ]
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "qwen3.5-plus"
      }
    }
  }
}
```

---

## 配置位置

- **主配置**: `openclaw.json`
- **模型配置**: `agents/main/agent/models.json`
- **API Base URL**: `https://coding.dashscope.aliyuncs.com/v1`
- **上下文窗口**: 128k tokens
- **最大输出**: 8192 tokens

---

## 模型选择建议

| 场景 | 推荐模型 |
|------|----------|
| 通用对话 | `qwen3.5-plus` |
| 代码开发 | `qwen3-coder-plus`, `qwen3-coder-next` |
| 长文档分析 | `glm-5` |
| 多模态任务 | `kimi-k2.5` |
| 办公/Agent | `minimax-m2.5` |

---

## Coding Plan 限制

- **计费方式**: 固定月费（非 Token 计费）
- **限制**: 每小时请求次数限制（非 Token 限额）
- **监控**: 资源守护者每 2 小时检查

---

## 相关文档

- [[01-overview]] - 系统架构总览
- [[02-cron-tasks]] - Cron 任务清单（各任务使用的模型）
- [coding-plan-models](../memory/coding-plan-models.md) - 详细模型文档

---

*返回主索引：[[../ARCHITECTURE]]*
