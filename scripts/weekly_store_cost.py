# -*- coding: utf-8 -*-
"""Weekly cost report from cost-tracker store"""
import json
import sys
from datetime import datetime, timedelta, timezone

sys.stdout.reconfigure(encoding='utf-8')

# Load store
with open(r'D:\OpenClaw\.openclaw\workspace\memory\cost-tracker\store.json', 'r', encoding='utf-8') as f:
    store = json.load(f)

# Week boundaries (UTC)
now_utc = datetime.now(timezone.utc)
week_start = now_utc - timedelta(days=7)

print(f"Report period: {week_start.isoformat()}Z to {now_utc.isoformat()}Z")
print()

# Aggregate per-model from all calls
model_stats = {}

sessions = store.get('sessions', {})
total_calls = 0
total_tokens = 0
total_cost = 0.0

for sess_key, sess_data in sessions.items():
    for call in sess_data.get('calls', []):
        ts_str = call.get('timestamp', '')
        try:
            if 'T' in ts_str:
                dt = datetime.fromisoformat(ts_str.replace('Z', '+00:00'))
                dt_utc = dt.replace(tzinfo=None) if dt.tzinfo else dt
            else:
                dt_utc = datetime.fromtimestamp(float(ts_str)/1000 if float(ts_str) > 1e10 else float(ts_str))
        except:
            dt_utc = None
        
        # Only include if within last 7 days
        if dt_utc and dt_utc < week_start:
            continue
        
        model = call.get('model', 'unknown')
        input_tok = call.get('inputTokens', 0)
        output_tok = call.get('outputTokens', 0)
        call_cost = call.get('cost', 0.0)
        is_free = call.get('isFree', False)
        
        if model not in model_stats:
            model_stats[model] = {
                'calls': 0, 'input': 0, 'output': 0, 'total': 0, 'cost': 0.0, 'free': is_free
            }
        
        ms = model_stats[model]
        ms['calls'] += 1
        ms['input'] += input_tok
        ms['output'] += output_tok
        ms['total'] += input_tok + output_tok
        ms['cost'] += call_cost
        total_calls += 1
        total_tokens += input_tok + output_tok
        total_cost += call_cost

# Sort by cost (non-free first)
def sort_key(item):
    k, v = item
    if v['free']:
        return (1, -v['cost'])
    return (0, -v['cost'])

print(f"=== Weekly Model Cost Report ===")
print(f"Period: {(now_utc - timedelta(days=7)).strftime('%Y-%m-%d')} ~ {now_utc.strftime('%Y-%m-%d')}")
print()
print(f"Total: {total_calls} calls | {total_tokens:,} tokens | ~${total_cost:.4f}")
print()
print("Per-model breakdown:")
print("-" * 80)
for model, stats in sorted(model_stats.items(), key=sort_key):
    free_str = " [FREE]" if stats['free'] else ""
    print(f"  {model}{free_str}")
    print(f"    Calls: {stats['calls']} | Input: {stats['input']:,} | Output: {stats['output']:,} | Total: {stats['total']:,}")
    print(f"    Cost: ~${stats['cost']:.4f}")
    print()

print("=" * 80)
print(f"GRAND TOTAL: {total_calls} calls | {total_tokens:,} tokens | ~${total_cost:.4f}")
