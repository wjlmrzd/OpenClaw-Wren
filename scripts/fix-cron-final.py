import json
import re
from datetime import datetime
import sys
import io
import time as time_module
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

with open('D:/OpenClaw/.openclaw/workspace/memory/cron-jobs.json', 'rb') as f:
    data = bytearray(f.read())

original_len = len(data)
print(f"File size: {original_len} bytes")

# Find and fix ALL garbled bytes
# Pattern: a valid UTF-8 char followed by 0x3F (? replacement) 
# This appears as a lone ? between Chinese chars in the text

# Strategy: for each occurrence of [\u4e00-\u9fff][?][\u4e00-\u9fff] in the replaced text,
# check if the ? is a 0x3F byte and if it's replacing a valid continuation byte

# First, let's just do a byte-level replacement of 0x3F (question mark)
# that appears IN STRING CONTENT (between valid UTF-8 chars)
# But we need to be careful: JSON strings use 0x22 for quotes

# Better approach: identify all positions where we have a valid 3-byte UTF-8 char
# followed by 0x3F followed by what looks like valid UTF-8 continuation
# In those cases, the 0x3F was a corrupted continuation byte

# Simpler: replace ALL 0x3F bytes with a space, as long as they're not inside
# ASCII strings (like URLs, etc.)
# Actually, let's be more surgical: look for the specific pattern

# Parse with replacement to find positions
text_with_replacement = data.decode('utf-8', errors='replace')

# Find the specific broken characters
fixes_applied = 0

# Walk through the text and find suspicious ? characters
i = 0
text_bytes = data
new_data = bytearray(data)

# Find all 0x3F bytes
question_marks = [i for i, b in enumerate(data) if b == 0x3F]
print(f"Found {len(question_marks)} question marks in file")

# Check each ? to see if it breaks a UTF-8 sequence
for qpos in question_marks:
    # Check context: bytes before and after
    if qpos > 0 and qpos < len(data) - 1:
        before = data[qpos-1]
        after = data[qpos+1]
        
        # Case 1: 0x3F preceded by a 2-byte UTF-8 lead byte (C0-DF)
        # and followed by a valid UTF-8 continuation (80-BF)
        if 0xC0 <= before <= 0xDF and 0x80 <= after <= 0xBF:
            # The ? replaced a continuation byte of a 2-byte char
            # We can't know what it should be, but let's check if removing it helps
            # Actually, let's replace with a valid continuation byte like 0x80
            print(f"  Fix candidate at {qpos}: before={before:02X} after={after:02X} (2-byte seq)")
            # Replace ? with 0x80 (a valid continuation byte)
            new_data[qpos] = 0x80
            fixes_applied += 1
        
        # Case 2: preceded by a 3-byte UTF-8 lead byte (E0-EF)
        # and followed by valid continuation
        elif 0xE0 <= before <= 0xEF and 0x80 <= after <= 0xBF:
            print(f"  Fix candidate at {qpos}: before={before:02X} after={after:02X} (3-byte seq)")
            # This is a continuation byte that got replaced
            # Try replacing with 0x80
            new_data[qpos] = 0x80
            fixes_applied += 1
        
        # Case 3: preceded by a 4-byte UTF-8 lead byte (F0-F7)
        elif 0xF0 <= before <= 0xF7 and 0x80 <= after <= 0xBF:
            print(f"  Fix candidate at {qpos}: before={before:02X} after={after:02X} (4-byte seq)")
            new_data[qpos] = 0x80
            fixes_applied += 1

print(f"\nApplied {fixes_applied} byte-level fixes")

# Also fix the specific issue: the 健康 monitor name 
# Pattern: E9 8D 9B 3F 2C (監視 ?,)
pattern1 = bytes([0xE9, 0xA6, 0x83, 0xE5, 0xBD, 0x9E, 0x20, 0xE9, 0x8D, 0x8B, 0xE3, 0x83, 0xA5, 0xE6, 0x82, 0x8D, 0xE9, 0x90, 0xA9, 0xE6, 0x88, 0x9E, 0xE5, 0xB8, 0xB6, 0xE9, 0x8D, 0x9B, 0x3F, 0x2C])
pos1 = new_data.find(pattern1)
if pos1 >= 0:
    print(f"\nFixing 健康 monitor name at byte {pos1}")
    new_data[pos1+28] = 0x22  # Replace ? with closing quote
    print("Applied!")

# Now try parsing
print("\nAttempting JSON parse...")
try:
    text = new_data.decode('utf-8-sig', errors='replace')
    result = json.loads(text)
    jobs = result['jobs']
    print(f"✅ JSON parsed! Total: {len(jobs)} jobs")
    print(f"Disabled: {sum(1 for j in jobs if not j.get('enabled', True))}")
    
    # Write the fixed file
    with open('D:/OpenClaw/.openclaw/workspace/memory/cron-jobs.json', 'w', encoding='utf-8-sig') as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
    print("Fixed JSON written!")
    
    # ===== ANALYSIS =====
    print(f"\n{'='*50}")
    print(f"=== CRON 总览 ===")
    print(f"总数: {len(jobs)}")
    
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
            error_jobs.append((name, status, cron_expr, timeout, dur, consec, last, err))
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
    
    print(f"\n=== 调度重叠检测 (同分钟 >= 2 jobs) ===")
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
    
    crowded = False
    for m in sorted(minute_count.keys()):
        items = minute_count[m]
        if len(items) >= 2:
            crowded = True
            print(f"  :{m:02d} ({len(items)} jobs):")
            for name, to in items:
                print(f"    - {name} (timeout={to}s)")
    if not crowded:
        print("  (none - no overlaps)")
    
    print(f"\n=== 模型使用分布 ===")
    from collections import Counter
    models = Counter()
    for j in jobs:
        model = j.get('payload', {}).get('model', 'unknown')
        models[model] += 1
    for m, c in models.most_common():
        print(f"  {m}: {c}")
    
except json.JSONDecodeError as e:
    print(f"\n❌ JSON still broken at {e.pos}: {e.msg}")
    ctx_start = max(0, e.pos-100)
    ctx_end = min(len(data), e.pos+100)
    ctx_bytes = data[ctx_start:ctx_end]
    print(f"Bytes: {' '.join(f'{b:02X}' for b in ctx_bytes)}")
    try:
        print(f"Text: {ctx_bytes.decode('utf-8', errors='replace')}")
    except:
        pass
