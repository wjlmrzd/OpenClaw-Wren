import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

with open('D:/OpenClaw/.openclaw/workspace/memory/cron-jobs.json', 'rb') as f:
    data = f.read()

# Find line 35
line_num = 0
pos = 0
while pos < len(data):
    line_end = pos
    while line_end < len(data) and data[line_end] != 0x0A:
        line_end += 1
    line_num += 1
    if line_num == 35:
        print(f"Line 35 starts at byte {pos}")
        # Show all bytes in line 35
        line_bytes = data[pos:line_end]
        print(f"Length: {len(line_bytes)} bytes")
        # Show hex of first 200 bytes
        hex_str = ' '.join(f'{b:02X}' for b in line_bytes[:200])
        print(f"HEX: {hex_str}")
        # Check for invalid bytes
        for i, b in enumerate(line_bytes):
            if b < 32 and b not in (9, 10, 13):
                rel = pos + i
                print(f"  INVALID at offset {i} (byte {rel}): 0x{b:02X}")
        # Show as string, replacing invalid
        try:
            s = line_bytes.decode('utf-8')
            print(f"String: {repr(s[:100])}")
        except Exception as e:
            print(f"Decode error: {e}")
        break
    pos = line_end + 1
    if pos >= len(data):
        break

# Also search for the pattern "name" near the garbled section
print("\n\nSearching for garbled section near 'name'...")
for i in range(len(data) - 10):
    if data[i:i+4] == b'"nam' and data[i+4:i+7] == b'e":':
        # Found a "name": field, print context
        start = max(0, i-5)
        end = min(len(data), i+200)
        ctx = data[start:end]
        print(f"\nFound 'name': at byte {i}:")
        # Check for control chars
        for j, b in enumerate(ctx):
            if b < 32 and b not in (9, 10, 13):
                print(f"  INVALID at offset {j} (byte {start+j}): 0x{b:02X}")
