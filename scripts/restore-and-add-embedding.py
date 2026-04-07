import json

# 从 gateway 获取的完整配置 (第一次 gateway config.get 的结果)
# 用这个作为基础，因为包含正确的敏感值引用
config = {
    "meta": {"lastTouchedVersion": "0.2.0", "lastTouchedAt": "2026-04-03T10:20:00.000Z"},
    "env": {
        "PADDLEOCR_OCR_API_URL": "${PADDLEOCR_OCR_API_URL}",
        "PADDLEOCR_ACCESS_TOKEN": "${PADDLEOCR_ACCESS_TOKEN}"
    },
    "wizard": {"lastRunAt": "2026-04-02T04:48:06.454Z", "lastRunVersion": "0.2.0", "lastRunCommand": "doctor", "lastRunMode": "local"},
    "logging": {"level": "info"},
    "browser": {"enabled": True, "controlToken": "${GATEWAY_CONTROL_TOKEN}"},
    "auth": {
        "profiles": {
            "minimax-coding-plan:default": {"provider": "minimax-coding-plan", "mode": "api_key"},
            "dashscope-coding-plan:default": {"provider": "dashscope-coding-plan", "mode": "api_key"}
        },
        "order": {
            "minimax-coding-plan": ["minimax-coding-plan:default"],
            "dashscope-coding-plan": ["dashscope-coding-plan:default"]
        }
    },
    "models": {
        "mode": "merge",
        "providers": {
            "minimax-coding-plan": {
                "baseUrl": "https://api.minimaxi.com/anthropic",
                "apiKey": "${MINIMAX_API}",
                "api": "anthropic-messages",
                "models": [{"id": "minimax-2.7", "name": "minimax-2.7", "reasoning": False, "input": ["text", "image"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 204800, "maxTokens": 131072}]
            },
            "dashscope-coding-plan": {
                "baseUrl": "https://coding.dashscope.aliyuncs.com/v1",
                "apiKey": "${DASHSCOPE_API_KEY}",
                "api": "openai-completions",
                "models": [
                    {"id": "qwen3.5-plus", "name": "qwen3.5-plus", "reasoning": False, "input": ["text", "image"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 262144, "maxTokens": 32768},
                    {"id": "qwen3-coder-plus", "name": "qwen3-coder-plus", "reasoning": False, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 998400, "maxTokens": 65536},
                    {"id": "qwen3-coder-next", "name": "qwen3-coder-next", "reasoning": False, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 262144, "maxTokens": 65536},
                    {"id": "glm-5", "name": "glm-5", "reasoning": False, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 200000, "maxTokens": 16384},
                    {"id": "glm-4.7", "name": "glm-4.7", "reasoning": False, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 200000, "maxTokens": 128000},
                    {"id": "kimi-k2.5", "name": "kimi-k2.5", "reasoning": False, "input": ["text", "image"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 262144, "maxTokens": 32000},
                    {"id": "minimax-m2.5", "name": "minimax-m2.5", "reasoning": False, "input": ["text"], "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}, "contextWindow": 196608, "maxTokens": 65536}
                ]
            }
        }
    },
    "agents": {
        "defaults": {
            "model": {"primary": "minimax-coding-plan/minimax-2.7", "fallbacks": ["dashscope-coding-plan/glm-5"]},
            "imageModel": {"primary": "dashscope-coding-plan/qwen3.5-plus"},
            "models": {
                "minimax-coding-plan/minimax-2.7": {"alias": "minimax-2.7"},
                "dashscope-coding-plan/qwen3.5-plus": {"alias": "qwen3.5-plus"},
                "dashscope-coding-plan/qwen3-coder-plus": {"alias": "qwen3-coder-plus"},
                "dashscope-coding-plan/qwen3-coder-next": {"alias": "qwen3-coder-next"},
                "dashscope-coding-plan/glm-5": {"alias": "glm-5"},
                "dashscope-coding-plan/glm-4.7": {"alias": "glm-4.7"},
                "dashscope-coding-plan/kimi-k2.5": {"alias": "kimi-k2.5"},
                "dashscope-coding-plan/minimax-m2.5": {"alias": "minimax-m2.5"}
            },
            "workspace": "D:\\OpenClaw\\.openclaw\\workspace",
            "compaction": {"mode": "default", "memoryFlush": {"enabled": True, "softThresholdTokens": 4000}},
            "maxConcurrent": 4,
            "subagents": {"maxConcurrent": 8}
        }
    },
    "tools": {
        "media": {
            "image": {"enabled": True, "maxBytes": 10485760},
            "audio": {"enabled": True, "maxBytes": 20971520, "models": [{"type": "cli", "command": "whisper", "args": ["--model", "base", "{{MediaPath}}"], "timeoutSeconds": 60}]}
        }
    },
    "commands": {"native": "auto", "nativeSkills": "auto", "restart": True},
    "hooks": {"internal": {"enabled": True, "entries": {"session-memory": {"enabled": True}, "command-logger": {"enabled": True}, "boot-md": {"enabled": True}}}},
    "channels": {
        "telegram": {
            "name": "WrenBot", "enabled": True, "dmPolicy": "allowlist", "botToken": "${TELEGRAM_BOT_TOKEN}",
            "groups": {"-1003866951105": {"enabled": True, "topics": {"31": {"enabled": True}, "166": {"enabled": True}}}},
            "groupPolicy": "allowlist", "streamMode": "partial"
        },
        "feishu": {
            "defaultAccount": "main",
            "accounts": {"main": {"appId": "${FEISHU_APP_ID}", "appSecret": "${FEISHU_APP_SECRET}", "botName": "OpenClaw", "enabled": True, "dmPolicy": "pairing", "groupPolicy": "allowlist", "defaultUser": "${FEISHU_DEFAULT_USER}"}}
        }
    },
    "gateway": {"port": 18789, "mode": "local", "bind": "loopback", "controlUi": {"enabled": True, "basePath": "/openclaw", "allowInsecureAuth": False}, "auth": {"mode": "token", "token": "${GATEWAY_AUTH_TOKEN}"}, "tailscale": {"mode": "off", "resetOnExit": False}},
    "skills": {"install": {"nodeManager": "npm"}},
    "plugins": {
        "load": {"paths": ["D:\\OpenClaw\\.openclaw\\workspace\\plugins-graph-memory", "D:\\OpenClaw\\.openclaw\\workspace\\plugins-lossless-claw-enhanced"]},
        "entries": {
            "telegram": {"enabled": True},
            "feishu": {"enabled": True},
            "graph-memory": {
                "enabled": True,
                "config": {
                    "compactTurnCount": 10,
                    "recallMaxNodes": 4,
                    "recallMaxDepth": 1,
                    "dedupThreshold": 0.85,
                    "embedding": {
                        "apiKey": "${DASHSCOPE_API_KEY}",
                        "baseURL": "https://dashscope.aliyuncs.com/v1/embeddings",
                        "model": "text-embedding-v2",
                        "dimensions": 512
                    }
                }
            },
            "lossless-claw": {
                "enabled": True,
                "config": {
                    "contextThreshold": 0.8,
                    "incrementalMaxDepth": 2,
                    "freshTailCount": 8,
                    "leafChunkTokens": 15000,
                    "summaryModel": "minimax-coding-plan/minimax-2.7",
                    "summaryProvider": "minimax-coding-plan",
                    "expansionModel": "minimax-coding-plan/minimax-2.7",
                    "expansionProvider": "minimax-coding-plan"
                }
            }
        },
        "installs": {
            "graph-memory": {"source": "path", "sourcePath": "D:\\OpenClaw\\.openclaw\\workspace\\plugins-graph-memory", "installPath": "D:\\OpenClaw\\.openclaw\\workspace\\plugins-graph-memory", "version": "1.5.6", "installedAt": "2026-04-02T14:35:04.346Z"},
            "lossless-claw": {"source": "path", "sourcePath": "D:\\OpenClaw\\.openclaw\\workspace\\plugins-lossless-claw-enhanced", "installPath": "D:\\OpenClaw\\.openclaw\\workspace\\plugins-lossless-claw-enhanced", "version": "0.5.2", "installedAt": "2026-04-02T14:35:13.834Z"}
        }
    }
}

# 写入文件 (UTF-8 with BOM，与原文件格式一致)
fpath = r'D:\OpenClaw\.openclaw\openclaw.json'
with open(fpath, 'w', encoding='utf-8', newline='') as f:
    # 写入 BOM
    f.write('\ufeff')
    # 写入 JSON，使用 tab 缩进保持原格式风格
    json.dump(config, f, indent='\t', ensure_ascii=False)
    f.write('\n')

print("Done! Config restored with embedding added.")
print("graph-memory config now has:", list(config['plugins']['entries']['graph-memory']['config'].keys()))