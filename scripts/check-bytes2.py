import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

with open('D:/OpenClaw/.openclaw/workspace/memory/cron-jobs.json', 'rb') as f:
    data = f.read()

pos = 960
start = max(0, pos-50)
end = min(len(data), pos+100)
chunk = data[start:end]

print(f"Position {start}-{end}:")
hex_str = ' '.join(f'{b:02X}' for b in chunk)
print(f"HEX: {hex_str}")
# Show which chars are suspicious
for i, b in enumerate(chunk):
    rel = start + i
    if b < 32 and b not in (9, 10, 13):
        print(f"  [POS {rel}] INVALID BYTE: 0x{b:02X}")
    if b == 0x0D:
        print(f"  [POS {rel}] CR (0x0D)")
    if b == 0x0A:
        print(f"  [POS {rel}] LF (0x0A)")

# Also show context as string
try:
    ctx = chunk.decode('utf-8')
    print(f"Context: {repr(ctx)}")
except:
    # Show byte by byte
    chars = []
    for b in chunk:
        if 32 <= b <= 126:
            chars.append(chr(b))
        else:
            chars.append(f'\\x{b:02x}')
    print(f"Context: {repr(''.join(chars))}")
