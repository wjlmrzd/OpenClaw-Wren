# Fast weekly cost - limited scan
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

# Get all jsonl files sorted by modification time
all_files = []
for fpath in glob.glob(SESSIONS_DIR + '/*.jsonl'):
    if os.path.basename(fpath) == 'sessions.json':
        continue
    try:
        mtime = os.path.getmtime(fpath)
        if datetime.fromtimestamp(mtime) > WEEK_AGO:
            all_files.append((mtime, fpath))
    except:
        pass

all_files.sort(reverse=True)
recent_files = [f for _, f in all_files[:500]]  # Top 500 recent files

print(f'Files to scan (last 7 days): {len(recent_files)}', flush=True)

for fpath in recent_files:
    files_checked += 1
    try:
        with open(fpath, 'r', encoding='utf-8', errors='ignore') as fp:
            for line in fp:
                line = line.strip()
                if not line or line[0] != '{':
                    continue
                try:
                    entry = json.loads(line)
                except:
                    continue
                
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

print(f'Files checked: {files_checked}, Usage entries: {count}', flush=True)
print('MODEL BREAKDOWN:', flush=True)

results = []
total_cost = 0
for m, s in sorted(stats.items(), key=lambda x: -x[1]['tokens']):
    p = get_pricing(m)
    cost = (s['input'] / 1_000_000) * p['input'] + \
           (s['output'] / 1_000_000) * p['output'] + \
           (s['cacheRead'] / 1_000_000) * p['cache_read']
    results.append((m, s, cost))
    total_cost += cost

for m, s, cost in results:
    print(f'{m}|{s["calls"]}|{s["tokens"]}|{s["input"]}|{s["output"]}|{s["cacheRead"]}|{cost:.6f}')

total_tokens = sum(s['tokens'] for _, s, _ in results)
print(f'TOTAL|{total_tokens}|{total_cost:.6f}')
