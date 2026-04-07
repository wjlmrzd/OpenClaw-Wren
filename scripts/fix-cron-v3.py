import json
import re
from datetime import datetime
import sys
import io
import time as time_module
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

with open('D:/OpenClaw/.openclaw/workspace/memory/cron-jobs.json', 'rb') as f:
    data = bytearray(f.read())

# The corruption pattern: 
# 1. E9 94 9B 3F 32 3A 30 30 -> E9 94 9B (鍔=corrupt) + 3F + 2:00
#    The 3F replaced what should be: 80 (from E2 80 9D = " right quote)
#    But wait, E9 94 9B is a valid 3-byte char (鍔)
#    E2 80 9D = " (right double quote)
#    After corruption: E9 94 9B 3F (3F replaces 80 from E2)
#    And then the E2 82 AC (€) was also partially lost
# Actually: the original was a CJK char + " + :00
# The " was E2 80 9D (3 bytes), but it got corrupted
# The Euro € (E2 82 AC) might have also been involved
# Pattern: E9 94 9B XX 3F 32 3A 30 30 where XX might be AC (€) and 3F replaces 80

# Simpler fix: find E9 94 9B followed by ? followed by ASCII -> replace ? with 80
# E9 94 9B = CJK char, next char would be a closing quote (E2 80 9D), but we see 3F
# Actually let me just find: valid 3-byte UTF-8 char followed by 3F followed by digit
# Replace the 3F with 0x80
count = 0
for i in range(1, len(data)-2):
    b0, b1, b2, b3 = data[i-1], data[i], data[i+1], data[i+2] if i+2 < len(data) else 0
    # Check if b1 is a valid 3-byte UTF-8 lead (E0-EF)
    if 0xE0 <= b0 <= 0xEF and b1 == 0x3F and 0x30 <= b3 <= 0x39:
        # This ? replaced a continuation byte
        data[i] = 0x80  # Replace with valid continuation byte
        count += 1

print(f"Applied {count} fixes for continuation byte replacements")

# Also fix the 健康 monitor name
pattern1 = bytes([0xE9, 0xA6, 0x83, 0xE5, 0xBD, 0x9E, 0x20, 0xE9, 0x8D, 0x8B, 0xE3, 0x83, 0xA5, 0xE6, 0x82, 0x8D, 0xE9, 0x90, 0xA9, 0xE6, 0x88, 0x9E, 0xE5, 0xB8, 0xB6, 0xE9, 0x8D, 0x9B, 0x3F, 0x2C])
pos1 = data.find(pattern1)
if pos1 >= 0:
    data[pos1+28] = 0x22
    print("Fixed 健康 monitor name")

# Now parse
print("\nParsing JSON...")
try:
    text = data.decode('utf-8', errors='replace')
    result = json.loads(text)
    jobs = result['jobs']
    print(f"✅ Success! Total: {len(jobs)} jobs")
    
    # Write fixed file
    with open('D:/OpenClaw/.openclaw/workspace/memory/cron-jobs.json', 'w', encoding='utf-8-sig') as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
    print("Fixed file written!")
    
    # ===== ANALYSIS =====
    print(f"\n{'='*50}")
    print(f"=== CRON 总览 ===")
    print(f"总数: {len(jobs)}")
    print(f"已禁用: {sum(1 for j in jobs if not j.get('enabled', True))}")
    
    print(f"\n=== 错误/超时任务 ===")
    error_jobs = []
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
            error_jobs.append({'name': name, 'status': status, 'schedule': cron_expr, 'timeout': timeout, 'dur': dur, 'consec': consec, 'last': last, 'err': err})
            print(f"  [{status}] {name}")
            print(f"    schedule={cron_expr} timeout={timeout}s dur={dur/1000:.0f}s consec={consec} last={last}")
            print(f"    err: {err}")
    if not error_jobs:
        print("  (none)")
    
    print(f"\n=== 超过7天未运行 ===")
    now_ms = time_module.time() * 1000
    seven_days = 7 * 86400000
    stale_jobs = []
    for j in jobs:
        s = j.get('state', {})
        last_run = s.get('lastRunAtMs')
        if last_run and (now_ms - last_run) > seven_days:
            name = j.get('name', j['id'])[:50]
            last = datetime.fromtimestamp(last_run/1000).strftime('%Y-%m-%d %H:%M')
            stale_jobs.append((name, last))
            print(f"  {name}: lastRun={last}")
    if not stale_jobs:
        print("  (none)")
    
    print(f"\n=== 调度重叠检测 ===")
    from collections import defaultdict, Counter
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
    
    crowded = False
    for m in sorted(minute_count.keys()):
        items = minute_count[m]
        if len(items) >= 2:
            crowded = True
            print(f"  :{m:02d} ({len(items)} jobs):")
            for name, to in items:
                print(f"    - {name} (timeout={to}s)")
    if not crowded:
        print("  (none)")
    
    print(f"\n=== 模型使用分布 ===")
    models = Counter()
    for j in jobs:
        model = j.get('payload', {}).get('model', 'unknown')
        models[model] += 1
    for m, c in models.most_common():
        print(f"  {m}: {c}")
    
    # Save analysis for summary
    print(f"\n{'='*50}")
    print(f"SUMMARY:")
    print(f"  Total: {len(jobs)}")
    print(f"  Errors: {len(error_jobs)}")
    print(f"  Stale: {len(stale_jobs)}")
    print(f"  Crowded minutes: {sum(1 for v in minute_count.values() if len(v)>=2)}")
        
except json.JSONDecodeError as e:
    print(f"\n❌ JSON still broken at {e.pos}: {e.msg}")
    ctx_start = max(0, e.pos-80)
    ctx_end = min(len(data), e.pos+80)
    ctx_bytes = data[ctx_start:ctx_end]
    print(f"Bytes: {' '.join(f'{b:02X}' for b in ctx_bytes)}")
    print(f"Text: {ctx_bytes.decode('utf-8', errors='replace')}")
