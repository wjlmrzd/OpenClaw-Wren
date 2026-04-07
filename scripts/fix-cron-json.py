import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

with open('D:/OpenClaw/.openclaw/workspace/memory/cron-jobs.json', 'rb') as f:
    data = bytearray(f.read())

# Fix the corrupted name field at line 35
# Pattern: after "監視鍛" (bytes E9 8D 9B) comes 3F (?) instead of closing quote (22)
# Original bytes: ...E9 8D 9B 3F 2C 0D (should be: E9 8D 9B 22 2C 0D)
# Location: around byte 1097
print(f"Before fix: bytes 1093-1102: {' '.join(f'{b:02X}' for b in data[1093:1102])}")
print(f"  as string: {data[1093:1102].decode('utf-8', errors='replace')}")

# Fix: replace the ? with a quote
data[1098] = 0x22  # 0x3F -> 0x22

print(f"After fix: bytes 1093-1102: {' '.join(f'{b:02X}' for b in data[1093:1102])}")
print(f"  as string: {data[1093:1102].decode('utf-8', errors='replace')}")

# Now validate JSON
import json
try:
    text = data.decode('utf-8')
    json.loads(text)
    print("\nJSON is valid!")
    # Write back
    with open('D:/OpenClaw/.openclaw/workspace/memory/cron-jobs.json', 'wb') as f:
        f.write(data)
    print("File written.")
except json.JSONDecodeError as e:
    print(f"\nStill invalid at {e.pos}: {e.msg}")
    print(f"Context: {repr(text[max(0,e.pos-50):e.pos+50])}")
