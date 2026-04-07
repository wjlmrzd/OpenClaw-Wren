# Weekly cost analysis - correct JSONL format
import json
import os
import glob
from datetime import datetime, timedelta
from collections import defaultdict

SESSIONS_DIR = r'D:\OpenClaw\.openclaw\agents\main\sessions'
WEEK_AGO = datetime.now() - timedelta(days=7)

PRICING = {
    'minimax-2.7': {'input': 0.015, 'output': 0.06, 'cache_read': 0.003},
    'minimax-m2.5': {'input': 0.015, 'output': 0.06, 'cache_read': 0.003},
    'qwen3.5-plus': {'input': 0.0005, 'output': 0.002, 'cache_read': 0},
    'qwen3-coder-plus': {'input': 0.001, 'output': 0.004, 'cache_read': 0},
    'qwen3-coder-next': {'input': 0.001, 'output': 0.004, 'cache_read': 0},
    'glm-5': {'input': 0.001, 'output': 0.004, 'cache_read': 0},
    'glm-4.7': {'input': 0.001, 'output': 0.004, 'cache_read': 0},
    'kimi-k2.5': {'input': 0.001, 'output': 0.004, 'cache_read': 0},
}

def get_pricing(model):
    model_lower = model.lower()
    for k, v in PRICING.items():
        if k.lower() in model_lower or model_lower in k.lower():
            return v
    return {'input': 0.001, 'output': 0.004, 'cache_read': 0}

stats = defaultdict(lambda: {'calls': 0, 'tokens': 0, 'input': 0, 'output': 0, 'cacheRead': 0, 'cacheWrite': 0})
count = 0
files_checked = 0

# Scan all jsonl files
for fpath in glob.glob(SESSIONS_DIR + '/*.jsonl'):
    if os.path.basename(fpath) == 'sessions.json':
        continue
    try:
        mtime = datetime.fromtimestamp(os.path.getmtime(fpath))
        if mtime < WEEK_AGO:
            continue
    except:
        continue
    
    files_checked += 1
    try:
        with open(fpath, 'r', encoding='utf-8', errors='ignore') as fp:
            for line in fp:
                line = line.strip()
                if not line:
                    continue
                try:
                    entry = json.loads(line)
                except:
                    continue
                
                # Format: entry['type'] == 'message' and entry['message']['role'] == 'assistant'
                if entry.get('type') != 'message':
                    continue
                msg = entry.get('message', {})
                if msg.get('role') != 'assistant':
                    continue
                usage = msg.get('usage', {})
                if not usage or not usage.get('totalTokens'):
                    continue
                
                model = msg.get('model') or msg.get('provider') or 'unknown'
                stats[model]['calls'] += 1
                stats[model]['tokens'] += usage.get('totalTokens', 0)
                stats[model]['input'] += usage.get('input', 0)
                stats[model]['output'] += usage.get('output', 0)
                stats[model]['cacheRead'] += usage.get('cacheRead', 0)
                stats[model]['cacheWrite'] += usage.get('cacheWrite', 0)
                count += 1
    except Exception as e:
        pass

print(f'Files checked: {files_checked}, Usage entries: {count}')
print()

results = []
total_cost = 0
for m, s in sorted(stats.items(), key=lambda x: -x[1]['tokens']):
    p = get_pricing(m)
    cost = (s['input'] / 1_000_000) * p['input'] + \
           (s['output'] / 1_000_000) * p['output'] + \
           (s['cacheRead'] / 1_000_000) * p['cache_read']
    results.append((m, s, cost))
    total_cost += cost

print('MODEL BREAKDOWN:')
for m, s, cost in results:
    print(f'{m}: calls={s["calls"]} tokens={s["tokens"]:,} input={s["input"]:,} output={s["output"]:,} cacheRead={s["cacheRead"]:,} cost=${cost:.6f}')

total_tokens = sum(s['tokens'] for _, s, _ in results)
print(f'TOTAL: tokens={total_tokens:,} est_cost=${total_cost:.6f}')
