import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

with open('D:/OpenClaw/.openclaw/workspace/memory/cron-jobs.json', 'rb') as f:
    data = bytearray(f.read())

# Find the garbled section: look for "name": "..." pattern followed by ?,
# specifically in the 健康 monitor job name
print("Looking for garbled name field...")

# Search for the pattern: after Chinese text, there's a '?' followed by ',' before end of line
# The corrupted name is: "馃彞 鍋ュ悍鐩戞帶鍛?,"
# which should be: "馃彞 鍋ュ悍鐩戞帶鍛?","
# Bytes: E9 A6 83 E5 BD 9E 20 E9 8D 8B E3 83 A5 E6 82 8D E9 90 A9 E6 88 9E E5 B8 B6 E9 8D 9B 3F 2C
# Should be: E9 A6 83 E5 BD 9E 20 E9 8D 8B E3 83 A5 E6 82 8D E9 90 A9 E6 88 9E E5 B8 B6 E9 8D 9B 22 2C
# The ? at 0x3F should be 0x22 (closing quote)

# Find the sequence
pattern = bytes([0xE9, 0xA6, 0x83, 0xE5, 0xBD, 0x9E, 0x20, 0xE9, 0x8D, 0x8B, 0xE3, 0x83, 0xA5, 0xE6, 0x82, 0x8D, 0xE9, 0x90, 0xA9, 0xE6, 0x88, 0x9E, 0xE5, 0xB8, 0xB6, 0xE9, 0x8D, 0x9B])
pos = data.find(pattern)
if pos >= 0:
    print(f"Found pattern at byte {pos}")
    # Check what's after
    after = data[pos+len(pattern):pos+len(pattern)+5]
    print(f"After pattern: {' '.join(f'{b:02X}' for b in after)}")
    if after[0] == 0x3F:  # ?
        print(f"Found garbled ? at byte {pos+len(pattern)}")
        print(f"Fixing: replacing 3F with 22")
        data[pos+len(pattern)] = 0x22
        print("Fixed!")
    else:
        print(f"After pattern is not ?: {after}")
else:
    print("Pattern not found - trying alternative search")
    # Try searching for just the last few bytes before the ?
    alt_pattern = bytes([0xE5, 0xB8, 0xB6, 0xE9, 0x8D, 0x9B])
    pos = data.find(alt_pattern)
    if pos >= 0:
        print(f"Found alt pattern at byte {pos}")
        after = data[pos+len(alt_pattern):pos+len(alt_pattern)+10]
        print(f"After: {' '.join(f'{b:02X}' for b in after)}")
        # Find the ? in the next few bytes
        for i, b in enumerate(after):
            if b == 0x3F:
                fix_pos = pos + len(alt_pattern) + i
                print(f"Found ? at byte {fix_pos}, fixing...")
                data[fix_pos] = 0x22
                print("Fixed!")
                break

# Verify JSON
import json
try:
    text = data.decode('utf-8-sig')  # Handle BOM
    json.loads(text)
    print("\n✅ JSON is valid!")
    with open('D:/OpenClaw/.openclaw/workspace/memory/cron-jobs.json', 'wb') as f:
        f.write(data)
    print("File written successfully.")
except json.JSONDecodeError as e:
    print(f"\n❌ Still invalid at {e.pos}: {e.msg}")
    ctx_start = max(0, e.pos-60)
    ctx_end = min(len(data), e.pos+60)
    ctx = data[ctx_start:ctx_end]
    print(f"Bytes: {' '.join(f'{b:02X}' for b in ctx)}")
    print(f"Chars: {ctx.decode('utf-8', errors='replace')}")
