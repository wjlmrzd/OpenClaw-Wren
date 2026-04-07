import json
import re
from datetime import datetime
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

with open('D:/OpenClaw/.openclaw/workspace/memory/cron-jobs.json', 'r', encoding='utf-8-sig') as f:
    raw = f.read()

# Remove bad control chars
clean = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]', '?', raw)
try:
    data = json.loads(clean)
except json.JSONDecodeError as e:
    print(f"JSON error: {e}")
    # Try to find and fix
    print(f"Position: {e.pos}")
    print(f"Context: {clean[max(0,e.pos-50):e.pos+50]}")
    exit(1)

jobs = data['jobs']
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
        err = s.get('lastError', '')[:80]
        last = datetime.fromtimestamp(s.get('lastRunAtMs', 0)/1000).strftime('%m-%d %H:%M') if s.get('lastRunAtMs') else 'never'
        print(f"  [{status}] {name}")
        print(f"    dur={dur/1000:.0f}s consec={consec} last={last}")
        print(f"    err: {err}")

print(f"\n=== 超过7天未运行 ===")
import time
now_ms = time.time() * 1000
seven_days = 7 * 86400000
for j in jobs:
    s = j.get('state', {})
    last_run = s.get('lastRunAtMs')
    if last_run and (now_ms - last_run) > seven_days:
        name = j.get('name', j['id'])[:50]
        last = datetime.fromtimestamp(last_run/1000).strftime('%Y-%m-%d %H:%M')
        print(f"  {name}: lastRun={last}")

print(f"\n=== 调度重叠检测 (每分钟) ===")
from collections import defaultdict
minute_count = defaultdict(int)
for j in jobs:
    sched = j.get('schedule', {})
    if sched.get('kind') == 'cron':
        expr = sched.get('expr', '')
        # Parse minute field
        parts = expr.split()
        if parts:
            minute = parts[0]
            minute_count[minute] += 1

for m, count in sorted(minute_count.items(), key=lambda x: -x[1])[:10]:
    if count >= 3:
        print(f"  Minute {m}: {count} jobs")
