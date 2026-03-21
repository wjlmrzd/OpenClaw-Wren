# 阿里云百炼 Coding Plan 支持模型列表

> 记录时间: 2026-03-21
> 来源: 阿里云官方文档及技术社区

## 支持的模型 (共8款)

### 通义千问 (阿里自研)
| 模型ID | 说明 |
|--------|------|
| `qwen3.5-plus` | 旗舰模型，3970亿参数，仅激活170亿，推理/编程/Agent能力强 |
| `qwen3-max` / `qwen3-max-2026-01-23` | 通义千问Max版本 |
| `qwen3-coder-next` | 编程专用模型 |
| `qwen3-coder-plus` | 编程增强版 |

### 智谱 GLM
| 模型ID | 说明 |
|--------|------|
| `glm-5` | 智谱最新旗舰开源模型，长任务表现领先，编程能力比肩 Claude Opus 4.5 |
| `glm-4.7` | GLM 4.7 版本 |

### 月之暗面 Kimi
| 模型ID | 说明 |
|--------|------|
| `kimi-k2.5` | 多模态和编程能力突出 |

### MiniMax
| 模型ID | 说明 |
|--------|------|
| `minimax-m2.5` / `minimax-text-2.5` | 专为Agent场景设计，Excel/PPT等Office场景表现优秀 |

## OpenClaw 配置参考

```json
{
  "models": {
    "mode": "merge",
    "providers": {
      "bailian": {
        "baseUrl": "https://coding.dashscope.aliyuncs.com/v1",
        "apiKey": "YOUR_API_KEY",
        "api": "openai-completions",
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
    }
  }
}
```

## 注意事项

1. **模型别名**: 在 OpenClaw 中使用短别名如 `kimi-k2.5`、`glm-5` 等
2. **避免使用**: `dashscope-coding-plan/kimi-k2.5` 这种完整路径格式在 cron 中可能不识别
3. **配置地址**: `~/.openclaw/openclaw.json`
4. **API Key**: Coding Plan 有专属的 API Key，与百炼按量计费的 Key 不互通

## 模型选择建议

- **通用编程**: `qwen3.5-plus`, `glm-5`
- **代码生成**: `qwen3-coder-plus`, `qwen3-coder-next`
- **Agent/办公**: `minimax-m2.5`
- **多模态**: `kimi-k2.5`
