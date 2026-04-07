import json
import re
from datetime import datetime
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

with open('D:/OpenClaw/.openclaw/workspace/memory/cron-jobs.json', 'r', encoding='utf-8-sig') as f:
    raw = f.read()

# Fix all corrupted ? bytes that break JSON
# Pattern: valid UTF-8 char followed by ? that should be a closing quote or continuation
# Strategy: replace all lone 0x3F bytes that are NOT inside quoted strings

# Parse with strict=False to handle some corruption
try:
    data = json.loads(raw, strict=False)
    jobs = data['jobs']
    print(f"Total jobs: {len(jobs)}")
except json.JSONDecodeError as e:
    print(f"JSON still broken at {e.pos}: {e.msg}")
    print(f"Context: {repr(raw[max(0,e.pos-50):e.pos+50])}")
    exit(1)

print(f"=== CRON 总览 ===")
print(f"总数: {len(jobs)}")
print(f"已禁用: {sum(1 for j in jobs if not j.get('enabled', True))}")

print(f"\n=== 错误/超时任务 ===")
for j in jobs:
    s = j.get('state', {})
    status = s.get('lastStatus', 'unknown')
    if status in ('error', 'timeout'):
        name = j.get('name', j['id'])[:50]
        dur = s.get('lastDurationMs', 0)
        consec = s.get('consecutiveErrors', 0)
        err = s.get('lastError', '')[:100]
        last = datetime.fromtimestamp(s.get('lastRunAtMs', 0)/1000).strftime('%m-%d %H:%M') if s.get('lastRunAtMs') else 'never'
        sched = j.get('schedule', {})
        cron_expr = sched.get('expr', sched.get('at', 'N/A'))
        timeout = j.get('payload', {}).get('timeoutSeconds', 'N/A')
        print(f"  [{status}] {name}")
        print(f"    schedule={cron_expr} timeout={timeout}s dur={dur/1000:.0f}s consec={consec} last={last}")
        print(f"    err: {err}")

print(f"\n=== 超过7天未运行 ===")
import time as time_module
now_ms = time_module.time() * 1000
seven_days = 7 * 86400000
for j in jobs:
    s = j.get('state', {})
    last_run = s.get('lastRunAtMs')
    if last_run and (now_ms - last_run) > seven_days:
        name = j.get('name', j['id'])[:50]
        last = datetime.fromtimestamp(last_run/1000).strftime('%Y-%m-%d %H:%M')
        print(f"  {name}: lastRun={last}")

print(f"\n=== 调度重叠检测 ===")
from collections import defaultdict
minute_count = defaultdict(list)
for j in jobs:
    if not j.get('enabled', True):
        continue
    sched = j.get('schedule', {})
    if sched.get('kind') == 'cron':
        expr = sched.get('expr', '')
        parts = expr.split()
        if parts and parts[0].isdigit():
            minute = int(parts[0])
            name = j.get('name', j['id'])[:30]
            timeout = j.get('payload', {}).get('timeoutSeconds', 0)
            minute_count[minute].append((name, timeout))

for m in sorted(minute_count.keys()):
    items = minute_count[m]
    if len(items) >= 2:
        print(f"  :{m:02d} ({len(items)} jobs):")
        for name, to in items:
            print(f"    - {name} (timeout={to}s)")

print(f"\n=== 模型使用分布 ===")
from collections import Counter
models = Counter()
for j in jobs:
    model = j.get('payload', {}).get('model', 'unknown')
    models[model] += 1
for m, c in models.most_common():
    print(f"  {m}: {c}")
