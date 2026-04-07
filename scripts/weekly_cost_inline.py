# -*- coding: utf-8 -*-
"""Weekly cost report inline"""
import json
from datetime import datetime, timezone, timedelta

with open(r'D:\OpenClaw\.openclaw\workspace\memory\cost-tracker\store.json', 'r', encoding='utf-8') as f:
    store = json.load(f)

now_utc = datetime.now(timezone.utc)
week_start = now_utc - timedelta(days=7)
week_start_naive = week_start.replace(tzinfo=None)

model_stats = {}
total_calls = 0
total_tokens = 0
total_cost = 0.0

for sess_key, sess_data in store.get('sessions', {}).items():
    for call in sess_data.get('calls', []):
        ts_str = call.get('timestamp', '')
        try:
            if 'T' in ts_str:
                dt = datetime.fromisoformat(ts_str.replace('Z', '+00:00'))
                dt_utc = dt.astimezone(timezone.utc).replace(tzinfo=None)
            else:
                ts = float(ts_str)
                dt_utc = datetime.utcfromtimestamp(ts / 1000 if ts > 1e10 else ts)
        except:
            continue
        if dt_utc < week_start_naive:
            continue

        model = call.get('model', 'unknown')
        input_tok = call.get('inputTokens', 0)
        output_tok = call.get('outputTokens', 0)
        call_cost = call.get('cost', 0.0)
        is_free = call.get('isFree', False)

        if model not in model_stats:
            model_stats[model] = {'calls': 0, 'input': 0, 'output': 0, 'total': 0, 'cost': 0.0, 'free': is_free}
        ms = model_stats[model]
        ms['calls'] += 1
        ms['input'] += input_tok
        ms['output'] += output_tok
        ms['total'] += input_tok + output_tok
        ms['cost'] += call_cost
        total_calls += 1
        total_tokens += input_tok + output_tok
        total_cost += call_cost

print(f'Period: {(now_utc - timedelta(days=7)).strftime("%Y-%m-%d")} ~ {now_utc.strftime("%Y-%m-%d")} (UTC)')
print(f'Total: {total_calls} calls | {total_tokens:,} tokens | ${total_cost:.4f}')
print()
for model, stats in sorted(model_stats.items(), key=lambda x: (-x[1]['cost'] if not x[1]['free'] else 0, x[1]['free'])):
    free_str = ' [FREE]' if stats['free'] else ''
    print(f'{model}{free_str}: {stats["calls"]} calls, {stats["total"]:,} tokens, ${stats["cost"]:.4f}')
    print(f'  Input: {stats["input"]:,} | Output: {stats["output"]:,}')
print()
print(f'GRAND TOTAL: ${total_cost:.4f}')
