import json, os, glob
from datetime import datetime, timedelta

SESSIONS_DIR = r'D:\OpenClaw\.openclaw\agents\main\sessions'
WEEK_AGO = datetime.now() - timedelta(days=7)

files = [f for f in glob.glob(SESSIONS_DIR + '/*.jsonl') 
         if datetime.fromtimestamp(os.path.getmtime(f)) > WEEK_AGO]

print(f'Found {len(files)} files from last 7 days')

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
        print(f'Error reading {fpath}: {e}')

print()
total_tokens = 0
for m, s in sorted(stats.items(), key=lambda x: -x[1]['tokens']):
    print(f'{m}: calls={s["calls"]} tokens={s["tokens"]:,} input={s["input"]:,} output={s["output"]:,} cacheRead={s["cacheRead"]:,}')
    total_tokens += s['tokens']

print(f'\nTotal tokens: {total_tokens:,}')
print(f'All-time from cost tracker: $2.202579, 3015 calls')
print(f'Week delta (cost tracker): 56 calls, 1,813,881 tokens')
