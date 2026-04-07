#!/usr/bin/env python3
import json
import os
import glob
from datetime import datetime, timedelta
from collections import defaultdict

week_ago = datetime.now() - timedelta(days=7)

data = defaultdict(lambda: {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0, "total": 0, "calls": 0})
files_checked = 0
files_with_usage = 0

pattern = r"D:\OpenClaw\.openclaw\agents\main\sessions\*.jsonl"
for path in glob.glob(pattern):
    try:
        mtime = os.path.getmtime(path)
        if datetime.fromtimestamp(mtime) < week_ago:
            continue
    except:
        pass
    
    files_checked += 1
    try:
        with open(path, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                    usage = obj.get('usage', {})
                    if not usage or not usage.get('totalTokens'):
                        continue
                    
                    files_with_usage += 1
                    model = obj.get('model') or usage.get('model') or 'unknown'
                    provider = obj.get('provider') or usage.get('provider') or 'unknown'
                    key = f"{provider}/{model}"
                    
                    data[key]['input'] += int(usage.get('input', 0) or 0)
                    data[key]['output'] += int(usage.get('output', 0) or 0)
                    data[key]['cacheRead'] += int(usage.get('cacheRead', 0) or 0)
                    data[key]['cacheWrite'] += int(usage.get('cacheWrite', 0) or 0)
                    data[key]['total'] += int(usage.get('totalTokens', 0) or 0)
                    data[key]['calls'] += 1
                except:
                    pass
    except Exception as e:
        pass

print(f"=== WEEKLY TOKEN USAGE REPORT (Mar 29 - Apr 5, 2026) ===")
print(f"Files checked (last 7 days): {files_checked}")
print(f"Total call entries with usage data: {files_with_usage}")
print()
print("MODEL BREAKDOWN:")
print("-" * 80)

totals = {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0, "total": 0, "calls": 0}

for key in sorted(data.keys()):
    v = data[key]
    print(f"\n{key}")
    print(f"  Calls: {v['calls']}")
    print(f"  Input: {v['input']:,} ({v['input']/1e6:.4f}M)")
    print(f"  Output: {v['output']:,} ({v['output']/1e6:.4f}M)")
    print(f"  CacheRead: {v['cacheRead']:,} ({v['cacheRead']/1e6:.4f}M)")
    print(f"  CacheWrite: {v['cacheWrite']:,} ({v['cacheWrite']/1e6:.4f}M)")
    print(f"  Total: {v['total']:,} ({v['total']/1e6:.4f}M)")
    
    for k in totals:
        totals[k] += v[k]

print("\n" + "=" * 80)
print("TOTALS:")
print(f"  Total Calls: {totals['calls']}")
print(f"  Input: {totals['input']:,} ({totals['input']/1e6:.4f}M)")
print(f"  Output: {totals['output']:,} ({totals['output']/1e6:.4f}M)")
print(f"  CacheRead: {totals['cacheRead']:,} ({totals['cacheRead']/1e6:.4f}M)")
print(f"  CacheWrite: {totals['cacheWrite']:,} ({totals['cacheWrite']/1e6:.4f}M)")
print(f"  Grand Total: {totals['total']:,} ({totals['total']/1e6:.4f}M)")
print()
print("NOTE: MiniMax calls may show cost=0 in session data (bundled pricing).")
print("Check MiniMax dashboard for actual costs.")
