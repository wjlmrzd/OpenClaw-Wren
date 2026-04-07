# Weekly cost - scan more files with line limit
import json
import glob
import os
from datetime import datetime

SESSIONS_DIR = r"D:\OpenClaw\.openclaw\agents\main\sessions"
WEEK_AGO = datetime.now().timestamp() - 7 * 86400

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

def get_price(model):
    ml = model.lower()
    for k, v in PRICING.items():
        if k.lower() in ml or ml in k.lower():
            return v
    return {"input": 0.001, "output": 0.004, "cache_read": 0}

stats = {}
total_entries = 0

# Get recent files
files = [f for f in glob.glob(SESSIONS_DIR + '/*.jsonl') if os.path.getmtime(f) > WEEK_AGO]
files = sorted(files, key=os.path.getmtime, reverse=True)[:50]

print(f"Scanning {len(files)} recent files (max 2000 lines each)...")

for fpath in files:
    try:
        with open(fpath, 'r', encoding='utf-8') as fp:
            lines = fp.readlines()[-2000:]  # Last 2000 lines
        
        for line in lines:
            line = line.strip()
            if not line or line[0] != '{':
                continue
            try:
                entry = json.loads(line)
            except:
                continue
            
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
                        total_entries += 1
    except:
        pass

print(f"Found {total_entries} usage entries\n")

# Calculate and output
print("=== 本周模型使用报告 (4/4 - 4/5) ===\n")
total_tokens = 0
total_cost = 0
results = []

for m, s in sorted(stats.items(), key=lambda x: -x[1]['tokens']):
    p = get_price(m)
    cost = (s['input'] / 1_000_000) * p['input'] + \
           (s['output'] / 1_000_000) * p['output'] + \
           (s['cacheRead'] / 1_000_000) * p.get('cache_read', 0)
    results.append((m, s, cost))
    total_tokens += s['tokens']
    total_cost += cost

for m, s, cost in results:
    emoji = "🤖" if "minimax" in m.lower() else "📝" if "qwen" in m.lower() else "🧠" if "glm" in m.lower() else "📊"
    print(f"{emoji} {m}")
    print(f"   调用 {s['calls']} 次 | Token {s['tokens']:,} (入 {s['input']:,} / 出 {s['output']:,} / 缓存 {s['cacheRead']:,})")
    print(f"   成本 ~${cost:.4f}\n")

print(f"━━━━━━━━━━━━━━")
print(f"📈 总计: {total_entries} 次调用 | {total_tokens:,} tokens")
print(f"💰 估算成本: ~${total_cost:.4f}")
print(f"\n生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M')}")
