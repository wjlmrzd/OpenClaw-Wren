# Quick weekly cost analysis - only check recent files
import json
import os
import glob
from datetime import datetime, timedelta

SESSIONS_DIR = r"D:\OpenClaw\.openclaw\agents\main\sessions"
WEEK_AGO = datetime.now() - timedelta(days=7)

# Pricing (approximate, USD per 1M tokens)
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

# Get recent files only
files = [f for f in glob.glob(SESSIONS_DIR + '/*.jsonl') 
         if datetime.fromtimestamp(os.path.getmtime(f)) > WEEK_AGO]

print(f"Scanning {len(files)} recent session files (last 7 days)...")

stats = {}
for fpath in files:
    try:
        with open(fpath, 'r', encoding='utf-8') as fp:
            for line in fp:
                line = line.strip()
                if not line:
                    continue
                try:
                    msg = json.loads(line)
                except:
                    continue
                if msg.get('role') == 'assistant' and 'usage' in msg:
                    u = msg['usage']
                    m = msg.get('model') or msg.get('provider') or 'unknown'
                    if m not in stats:
                        stats[m] = {'calls':0,'tokens':0,'input':0,'output':0,'cacheRead':0}
                    stats[m]['calls'] += 1
                    stats[m]['tokens'] += u.get('totalTokens',0)
                    stats[m]['input'] += u.get('input',0)
                    stats[m]['output'] += u.get('output',0)
                    stats[m]['cacheRead'] += u.get('cacheRead',0)
    except Exception as e:
        pass

# Output results
print()
total_tokens = 0
total_cost = 0
results = []
for m, s in sorted(stats.items(), key=lambda x: -x[1]['tokens']):
    p = get_pricing(m)
    cost = (s['input'] / 1_000_000) * p['input'] + \
           (s['output'] / 1_000_000) * p['output'] + \
           (s['cacheRead'] / 1_000_000) * p.get('cache_read', 0)
    
    results.append({
        'model': m,
        'calls': s['calls'],
        'tokens': s['tokens'],
        'input': s['input'],
        'output': s['output'],
        'cacheRead': s['cacheRead'],
        'cost': cost
    })
    
    total_tokens += s['tokens']
    total_cost += cost

# Print in order
for r in results:
    print(f"{r['model']}: calls={r['calls']} tokens={r['tokens']:,} cost=${r['cost']:.6f}")

print(f'\nTotal tokens: {total_tokens:,}')
print(f'Estimated total cost: ${total_cost:.6f}')
print(f'Generation time: {datetime.now().strftime("%Y-%m-%d %H:%M")}')
