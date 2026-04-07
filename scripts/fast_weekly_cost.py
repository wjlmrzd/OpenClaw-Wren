# Ultra-fast weekly cost - process only recent entries
import json
import os
import glob
from datetime import datetime, timedelta

SESSIONS_DIR = r"D:\OpenClaw\.openclaw\agents\main\sessions"
WEEK_AGO = datetime.now() - timedelta(days=7)

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
max_files = 200  # Limit to most recent 200 files

files = sorted(glob.glob(SESSIONS_DIR + '/*.jsonl'), key=os.path.getmtime, reverse=True)[:max_files]

print(f"Fast scan: {len(files)} most recent session files...")

for fpath in files:
    try:
        # Read last 100 lines only (most recent entries)
        with open(fpath, 'r', encoding='utf-8') as fp:
            lines = fp.readlines()[-100:]
        
        for line in lines:
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
                count += 1
    except:
        pass

print(f"Processed {count} usage entries")

# Output
print()
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
    print(f"{m}: calls={s['calls']} tokens={s['tokens']:,} cost=${cost:.6f}")

print(f'\nTotal tokens: {total_tokens:,}')
print(f'Estimated cost: ${total_cost:.6f}')
