# Weekly cost analysis - extract model usage from recent sessions
import json
import os
from datetime import datetime, timedelta
from collections import defaultdict

SESSIONS_DIR = r"D:\OpenClaw\.openclaw\agents\main\sessions"
WEEK_AGO = datetime.now() - timedelta(days=7)

# Pricing (approximate, USD per 1M tokens)
PRICING = {
    "minimax-2.7": {"input": 0.015, "output": 0.06, "cache_read": 0.003},
    "qwen3.5-plus": {"input": 0.0005, "output": 0.002, "cache_read": 0},
    "qwen3-coder-plus": {"input": 0.001, "output": 0.004, "cache_read": 0},
    "glm-5": {"input": 0.001, "output": 0.004, "cache_read": 0},
}

def get_model_key(msg):
    # Try different fields
    if msg.get("model"):
        return msg["model"]
    if msg.get("provider"):
        return msg["provider"]
    api = msg.get("api", "")
    if "dashscope" in api:
        return "qwen-family"
    if "minimax" in api:
        return "minimax-family"
    return "unknown"

def process_file(filepath):
    stats = []
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    msg = json.loads(line)
                except:
                    continue
                if msg.get("role") == "assistant" and "usage" in msg:
                    usage = msg["usage"]
                    model = get_model_key(msg)
                    tokens = usage.get("totalTokens", 0)
                    inp = usage.get("input", 0)
                    out = usage.get("output", 0)
                    cache_read = usage.get("cacheRead", 0)
                    stats.append({
                        "model": model,
                        "tokens": tokens,
                        "input": inp,
                        "output": out,
                        "cacheRead": cache_read,
                        "timestamp": msg.get("timestamp", 0)
                    })
    except Exception as e:
        pass
    return stats

# Get recent session files
files = []
for fname in os.listdir(SESSIONS_DIR):
    if not fname.endswith(".jsonl"):
        continue
    fpath = os.path.join(SESSIONS_DIR, fname)
    try:
        mtime = datetime.fromtimestamp(os.path.getmtime(fpath))
        if mtime > WEEK_AGO:
            files.append(fpath)
    except:
        pass

print(f"Scanning {len(files)} recent session files...")

all_stats = []
for fpath in files[:100]:  # Limit to avoid timeout
    all_stats.extend(process_file(fpath))

# Aggregate by model
model_stats = defaultdict(lambda: {"calls": 0, "tokens": 0, "input": 0, "output": 0, "cacheRead": 0})
for s in all_stats:
    m = s["model"]
    model_stats[m]["calls"] += 1
    model_stats[m]["tokens"] += s["tokens"]
    model_stats[m]["input"] += s["input"]
    model_stats[m]["output"] += s["output"]
    model_stats[m]["cacheRead"] += s["cacheRead"]

# Calculate costs
print("\n=== WEEKLY MODEL USAGE (Last 7 Days) ===\n")
total_tokens = 0
total_cost = 0
for model, stats in sorted(model_stats.items(), key=lambda x: -x[1]["tokens"]):
    # Get pricing
    price_key = None
    for k in PRICING:
        if k in model.lower() or model.lower() in k.lower():
            price_key = k
            break
    
    if price_key:
        p = PRICING[price_key]
        cost = (stats["input"] / 1_000_000) * p["input"] + \
               (stats["output"] / 1_000_000) * p["output"] + \
               (stats["cacheRead"] / 1_000_000) * p.get("cache_read", 0)
    else:
        cost = 0
    
    print(f"{model}:")
    print(f"  Calls:     {stats['calls']}")
    print(f"  Tokens:    {stats['tokens']:,}")
    print(f"  Input:     {stats['input']:,}")
    print(f"  Output:    {stats['output']:,}")
    print(f"  CacheRead: {stats['cacheRead']:,}")
    print(f"  Est.Cost:  ${cost:.6f}")
    print()
    
    total_tokens += stats["tokens"]
    total_cost += cost

print(f"Total: ~{total_tokens:,} tokens, ~${total_cost:.4f}")
print(f"\nAll-time (from cost tracker): $2.202579, 3015 calls")
