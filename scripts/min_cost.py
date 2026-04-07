# Minimal fast - just 10 most recent files
import json
import glob
import os
from datetime import datetime

SESSIONS_DIR = r"D:\OpenClaw\.openclaw\agents\main\sessions"

PRICING = {
    "minimax-2.7": {"input": 0.015, "output": 0.06, "cache_read": 0.003},
    "qwen3.5-plus": {"input": 0.0005, "output": 0.002, "cache_read": 0},
    "qwen3-coder-plus": {"input": 0.001, "output": 0.004, "cache_read": 0},
    "glm-5": {"input": 0.001, "output": 0.004, "cache_read": 0},
}

stats = {}
count = 0

files = sorted(glob.glob(SESSIONS_DIR + '/*.jsonl'), key=os.path.getmtime, reverse=True)[:10]

print(f"Scanning {len(files)} files...")

for fpath in files:
    name = os.path.basename(fpath)
    print(f"  {name}...", end=" ")
    try:
        with open(fpath, 'r', encoding='utf-8') as fp:
            lines = fp.readlines()
        
        local_count = 0
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
                        local_count += 1
                        count += 1
        print(f"{local_count} entries")
    except Exception as e:
        print(f"error: {e}")

print(f"\nTotal: {count} entries\n")

for m, s in sorted(stats.items(), key=lambda x: -x[1]['tokens']):
    p = next((v for k, v in PRICING.items() if k.lower() in m.lower() or m.lower() in k.lower()), {"input": 0.001, "output": 0.004, "cache_read": 0})
    cost = (s['input'] / 1_000_000) * p['input'] + (s['output'] / 1_000_000) * p['output'] + (s['cacheRead'] / 1_000_000) * p.get('cache_read', 0)
    print(f"{m}: calls={s['calls']} tokens={s['tokens']:,} cost=${cost:.6f}")
