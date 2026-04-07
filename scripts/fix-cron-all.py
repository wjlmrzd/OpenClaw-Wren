import json
import re
from datetime import datetime
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

with open('D:/OpenClaw/.openclaw/workspace/memory/cron-jobs.json', 'rb') as f:
    data = bytearray(f.read())

original_len = len(data)
print(f"File size: {original_len} bytes")

# Fix 1: Garbled name at line 35 - "馃彞 鍋ュ悍鐩戞帶鍛?,"
# Pattern: E9 8D 9B (監視) followed by 3F (?) instead of closing quote
pattern1 = bytes([0xE9, 0xA6, 0x83, 0xE5, 0xBD, 0x9E, 0x20, 0xE9, 0x8D, 0x8B, 0xE3, 0x83, 0xA5, 0xE6, 0x82, 0x8D, 0xE9, 0x90, 0xA9, 0xE6, 0x88, 0x9E, 0xE5, 0xB8, 0xB6, 0xE9, 0x8D, 0x9B])
pos1 = data.find(pattern1)
if pos1 >= 0:
    after = data[pos1+len(pattern1):pos1+len(pattern1)+5]
    print(f"Fix1 - Pattern1 found at {pos1}, after={after.hex()}")
    if after[0] == 0x3F:
        data[pos1+len(pattern1)] = 0x22
        print("Fix1 - Applied!")

# Fix 2: Look for any 0x3F in the message/name strings that break JSON
# Strategy: parse with errors='replace' to see the raw text, then find suspicious areas
text_replaced = data.decode('utf-8', errors='replace')

# Find the garbled 健康 monitor name: after the hex dump analysis, it's "馃彞 鍋ュ悍鐩戞帶鍛"
# and after that should come a closing quote
# Already fixed above

# Fix 3: Look for garbled Chinese chars in message fields
# Pattern: Chinese char followed by '?' that should be part of the Chinese text
# Find all occurrences of '?' in the replaced text
for m in re.finditer(r'[\u4e00-\u9fff][?][\u4e00-\u9fff]', text_replaced):
    pos = m.start()
    # Find this in the original bytes
    byte_pos = pos  # approximate
    print(f"Fix3 - Found garbled ? at text position {pos}: {repr(m.group())}")
    # Check if this ? is a 0x3F in the original
    if byte_pos < len(data) and data[byte_pos] == 0x3F:
        # Try to find what the char should be by looking at the context
        # In the 鏃舵€€ pattern, the ? replaced 0xAC from the Euro sign 0xE2 0x82 0xAC
        # Actually let's just replace the ? with a valid continuation or skip it
        # For now, mark it
        print(f"  Byte value: 0x3F")

# Now try to parse and fix the JSON by regex-manipulating the text
print("\nAttempting JSON repair...")

# The simplest approach: replace all lone '?' that appear to break strings
# with a safe placeholder, then parse
text = data.decode('utf-8-sig', errors='replace')

# Try to find the specific broken sections and repair
# The garbled 健康 monitor name: find "馃彞 鍋ュ悍鐩戞帶鍛" + ?
fix1_match = re.search(r'"name": ".*?鍋ュ悍鐩戞帶鍛[,]', text)
if fix1_match:
    print(f"Found garbled name field: {repr(fix1_match.group())}")
    # The correct text should have a closing quote before the comma
    fixed = re.sub(r'(鍋ュ悍鐩戞帶鍛)\?,', r'\1",', fix1_match.group())
    print(f"Fixed to: {repr(fixed)}")
    text = text[:fix1_match.start()] + fixed + text[fix1_match.end():]
    print("Applied fix1 to text")

# Try parsing
try:
    result = json.loads(text)
    print("\n✅ JSON parsed successfully!")
    jobs = result['jobs']
    print(f"Total jobs: {len(jobs)}")
    print(f"Disabled: {sum(1 for j in jobs if not j.get('enabled', True))}")
    
    # Write the fixed data back
    with open('D:/OpenClaw/.openclaw/workspace/memory/cron-jobs.json', 'w', encoding='utf-8-sig') as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
    print("Fixed JSON written to file!")
    
    # Now run the analysis
    print("\n\n=== CRON ANALYSIS ===")
    print(f"总数: {len(jobs)}")
    
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
    now_ms = __import__('time').time() * 1000
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
        
except json.JSONDecodeError as e:
    print(f"\n❌ JSON still broken at {e.pos}: {e.msg}")
    ctx_start = max(0, e.pos-80)
    ctx_end = min(len(text), e.pos+80)
    print(f"Context: {repr(text[ctx_start:ctx_end])}")
