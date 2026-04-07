import json, os, glob
from datetime import datetime, timedelta
from collections import defaultdict

SESSIONS_DIR = r'D:\OpenClaw\.openclaw\agents\main\sessions'
WEEK_AGO = datetime.now() - timedelta(days=7)

# Get files modified in last 7 days
recent_files = []
for f in glob.glob(SESSIONS_DIR + '/*.jsonl'):
    try:
        if datetime.fromtimestamp(os.path.getmtime(f)) > WEEK_AGO:
            recent_files.append(f)
    except:
        pass

print(f'Files modified last 7 days: {len(recent_files)}')

# Pricing (per 1M tokens, USD) - MiniMax and Dashscope official pricing
PRICING = {
    "minimax-2.7": {"input": 0.015, "output": 0.06, "cache_read": 0.003},
    "qwen3.5-plus": {"input": 0.0005, "output": 0.002, "cache_read": 0},
    "qwen3-coder-plus": {"input": 0.001, "output": 0.004, "cache_read": 0},
    "glm-5": {"input": 0.001, "output": 0.004, "cache_read": 0},
}

stats = defaultdict(lambda: {"calls":0,"tokens":0,"input":0,"output":0,"cacheRead":0,"sessions":0})
total_lines = 0

for fpath in recent_files:
    fname = os.path.basename(fpath)
    session_saw = False
    try:
        with open(fpath, 'r', encoding='utf-8', errors='ignore') as fp:
            for line in fp:
                total_lines += 1
                line = line.strip()
                if not line:
                    continue
                try:
                    msg = json.loads(line)
                except:
                    continue
                if msg.get('role') == 'assistant' and 'usage' in msg:
                    u = msg['usage']
                    m = (msg.get('model') or msg.get('provider') or 'unknown')
                    if not session_saw:
                        stats[m]['sessions'] += 1
                        session_saw = True
                    stats[m]['calls'] += 1
                    stats[m]['tokens'] += u.get('totalTokens', 0)
                    stats[m]['input'] += u.get('input', 0)
                    stats[m]['output'] += u.get('output', 0)
                    stats[m]['cacheRead'] += u.get('cacheRead', 0)
    except Exception as e:
        print(f'Error: {fpath}: {e}')

print(f'Lines processed: {total_lines}')
print()

# Calculate costs
results = []
for m, s in sorted(stats.items(), key=lambda x: -x[1]['tokens']):
    price_key = None
    for k in PRICING:
        if k in m.lower():
            price_key = k
            break
    if price_key:
        p = PRICING[price_key]
        cost = (s['input']/1e6)*p['input'] + (s['output']/1e6)*p['output'] + (s['cacheRead']/1e6)*p['cache_read']
    else:
        cost = 0
    results.append((m, s, cost))

print('=== WEEKLY MODEL USAGE REPORT ===')
for m, s, cost in results:
    print(f'Model: {m}')
    print(f'  Sessions: {s["sessions"]}')
    print(f'  API calls: {s["calls"]}')
    print(f'  Total tokens: {s["tokens"]:,}')
    print(f'  Input: {s["input"]:,}  Output: {s["output"]:,}  CacheRead: {s["cacheRead"]:,}')
    print(f'  Est. cost: ${cost:.4f}')
    print()

total_tokens = sum(s['tokens'] for _, s, _ in results)
total_cost = sum(c for _, _, c in results)
print(f'TOTAL: {total_tokens:,} tokens, ~${total_cost:.4f}')
