# Super fast - just last 3 files, last 50 lines each
import json
import glob
import os
from datetime import datetime

SESSIONS_DIR = r"D:\OpenClaw\.openclaw\agents\main\sessions"

stats = {}
files = sorted(glob.glob(SESSIONS_DIR + '/*.jsonl'), key=os.path.getmtime, reverse=True)[:3]
print(f"Scanning 3 most recent files...")

for fpath in files:
    print(f"Reading {os.path.basename(fpath)}...")
    try:
        with open(fpath, 'r', encoding='utf-8') as fp:
            lines = fp.readlines()[-50:]
        
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
                    stats[m] = {'calls':0,'tokens':0,'input':0,'output':0}
                stats[m]['calls'] += 1
                stats[m]['tokens'] += u.get('totalTokens',0)
                stats[m]['input'] += u.get('input',0)
                stats[m]['output'] += u.get('output',0)
    except Exception as e:
        print(f"Error: {e}")

print()
total_tokens = 0
for m, s in sorted(stats.items(), key=lambda x: -x[1]['tokens']):
    print(f"{m}: calls={s['calls']} tokens={s['tokens']:,}")
    total_tokens += s['tokens']
print(f"\nTotal tokens (sample): {total_tokens:,}")
