# Ultra-fast parsing of OpenClaw session JSONL
import json
import glob
import os
from datetime import datetime

SESSIONS_DIR = r"D:\OpenClaw\.openclaw\agents\main\sessions"
WEEK_AGO = datetime.now().timestamp() - 7 * 86400

# Pricing (USD per 1M tokens)
PRICING = {
    "minimax-2.7": {"input": 0.015, "output": 0.06, "cache_read": 0.003},
    "minimax-m2.5": {"input": 0.015, "output": 0.06, "cache_read": 0.003},
    "qwen3.5-plus": {"input": 0.0005, "output": 0.002, "cache_read": 0},
    "qwen3-coder-plus": {"input": 0.001, "output": 0.004, "cache_read": 0},
    "qwen3-coder-next": {"input": 0.001, "output": 0.004, "cache_read": 0},
    "glm-5": {"input": 0.001, "output": 0.004, "cache_read": 0},
    "glm-4.7": {"input": 0.001, "output": 0.004, "cache_read": 0},
    "kimi-k2.5": {"input": 0.001, "output": 0.004, "cache_read": 0},
}

def get_pricing(model):
    model_lower = model.lower()
    for k, v in PRICING.items():
        if k.lower() in model_lower or model_lower in k.lower():
            return v
    return {"input": 0.001, "output": 0.004, "cache_read": 0}

stats = {}
count = 0

# Get recent files (modified in last 7 days)
files = [f for f in glob.glob(SESSIONS_DIR + '/*.jsonl') 
         if os.path.getmtime(f) > WEEK_AGO]
files = sorted(files, key=os.path.getmtime, reverse=True)[:100]  # Most recent 100

print(f"Scanning {len(files)} recent files...")

for fpath in files:
    try:
        with open(fpath, 'r', encoding='utf-8') as fp:
            for line in fp:
                line = line.strip()
                if not line or line[0] != '{':
                    continue
                try:
                    entry = json.loads(line)
                except:
                    continue
                
                # Look for message entries with assistant role and usage
                if entry.get('type') == 'message':
                    msg = entry.get('message', {})
                    if msg.get('role') == 'assistant':
                        usage = msg.get('usage', {})
                        if usage:
                            model = msg.get('model') or msg.get('provider') or 'unknown'
                            if model not in stats:
                                stats[model] = {'calls':0,'tokens':0,'input':0,'output':0,'cacheRead':0}
                            stats[model]['calls'] += 1
                            stats[model]['tokens'] += usage.get('totalTokens',0)
                            stats[model]['input'] += usage.get('input',0)
                            stats[model]['output'] += usage.get('output',0)
                            stats[model]['cacheRead'] += usage.get('cacheRead',0)
                            count += 1
    except:
        pass

print(f"Found {count} usage entries\n")

# Output
print("=== 本周模型使用报告 ===\n")
total_tokens = 0
total_cost = 0
results = []
for m, s in sorted(stats.items(), key=lambda x: -x[1]['tokens']):
    p = get_pricing(m)
    cost = (s['input'] / 1_000_000) * p['input'] + \
           (s['output'] / 1_000_000) * p['output'] + \
           (s['cacheRead'] / 1_000_000) * p.get('cache_read', 0)
    
    results.append((m, s, cost))
    total_tokens += s['tokens']
    total_cost += cost

for m, s, cost in results:
    print(f"📊 {m}")
    print(f"   调用: {s['calls']} 次")
    print(f"   Token: {s['tokens']:,} (输入 {s['input']:,} / 输出 {s['output']:,} / 缓存 {s['cacheRead']:,})")
    print(f"   估算成本: ${cost:.4f}\n")
    total_cost += cost

print(f"━━━━━━━━━━━━━━")
print(f"总计: {count} 次调用, {total_tokens:,} tokens")
print(f"估算成本: ${total_cost:.4f}")
print(f"\n统计时间: {datetime.now().strftime('%Y-%m-%d %H:%M')}")
