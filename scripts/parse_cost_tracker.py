# Parse cost-tracker store.json for weekly report
import json
from datetime import datetime, timedelta

WEEK_AGO = datetime.now() - timedelta(days=7)

with open(r"D:\OpenClaw\.openclaw\workspace\memory\cost-tracker\store.json", 'r', encoding='utf-8') as f:
    data = json.load(f)

# Aggregate by model
stats = {}
week_calls = 0
week_tokens = 0
week_cost = 0

for session_id, session_data in data.get('sessions', {}).items():
    for call in session_data.get('calls', []):
        ts = datetime.fromisoformat(call['timestamp'].replace('Z', '+00:00'))
        if ts > WEEK_AGO:
            week_calls += 1
            week_tokens += call.get('totalTokens', 0)
            week_cost += call.get('cost', 0)
            
            model = call.get('model', 'unknown')
            if model not in stats:
                stats[model] = {'calls': 0, 'tokens': 0, 'cost': 0}
            stats[model]['calls'] += 1
            stats[model]['tokens'] += call.get('totalTokens', 0)
            stats[model]['cost'] += call.get('cost', 0)

print(f"=== 本周成本追踪报告 (cost-tracker) ===")
print(f"统计周期: {(datetime.now() - WEEK_AGO).days} 天\n")

for model, s in sorted(stats.items(), key=lambda x: -x[1]['tokens']):
    print(f"📊 {model}: {s['calls']} 次调用, {s['tokens']:,} tokens, ${s['cost']:.6f}")

print(f"\n📈 总计: {week_calls} 次调用, {week_tokens:,} tokens, ${week_cost:.6f}")
