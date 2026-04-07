# -*- coding: utf-8 -*-
import json, glob, os, sys
from datetime import datetime, timedelta

# Force UTF-8
sys.stdout.reconfigure(encoding='utf-8')

SESSIONS_DIR = r'D:\OpenClaw\.openclaw\agents\main\sessions'
WEEK_AGO = datetime.now() - timedelta(days=7)

# Pricing (per 1M tokens)
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
    ml = model.lower()
    for k, v in PRIVING.items():
        if k.lower() in ml or ml in k.lower():
            return v
    return {"input": 0.001, "output": 0.004, "cache_read": 0}

def calc_cost(model, input_tok, output_tok, cache_read=0):
    p = get_pricing(model)
    return (input_tok/1e6 * p["input"]) + (output_tok/1e6 * p["output"])

stats = {}
total_entries = 0
week_entries = 0
oldest_ts = None
newest_ts = None

# Get all files
files = glob.glob(SESSIONS_DIR + '/*.jsonl')
files.sort(key=os.path.getmtime, reverse=True)

print(f"Total session files: {len(files)}")
print(f"Week ago: {WEEK_AGO}")

# Check date range from file names (they contain timestamps)
sample_files = files[:5]
print("\nSample newest files:")
for f in sample_files:
    fname = os.path.basename(f)
    # Extract timestamp from filename if present
    print(f"  {fname} -> mtime={datetime.fromtimestamp(os.path.getmtime(f))}")

sample_old = files[-5:]
print("\nSample oldest files:")
for f in sample_old:
    fname = os.path.basename(f)
    print(f"  {fname} -> mtime={datetime.fromtimestamp(os.path.getmtime(f))}")

# Scan all files (limit to last 100 for speed test)
print(f"\nScanning last 100 files for date range check...")
min_ts = None
max_ts = None
for i, fpath in enumerate(files[:100]):
    try:
        with open(fpath, 'r', encoding='utf-8') as fp:
            lines = fp.readlines()
        for line in lines[-500:]:  # last 500 lines
            line = line.strip()
            if not line or line[0] != '{':
                continue
            try:
                entry = json.loads(line)
                ts = entry.get('ts') or entry.get('time') or entry.get('timestamp')
                if ts:
                    try:
                        if isinstance(ts, (int, float)):
                            dt = datetime.fromtimestamp(ts/1000 if ts > 1e10 else ts)
                        else:
                            dt = datetime.fromisoformat(str(ts).replace('Z', '+00:00'))
                        if min_ts is None or dt < min_ts:
                            min_ts = dt
                        if max_ts is None or dt > max_ts:
                            max_ts = dt
                    except:
                        pass
            except:
                pass
    except:
        pass

if min_ts and max_ts:
    print(f"\nDate range (from content): {min_ts} to {max_ts}")
else:
    print("\nCould not determine date range from content")
