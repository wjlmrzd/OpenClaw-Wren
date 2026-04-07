import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

with open('D:/OpenClaw/.openclaw/workspace/memory/cron-jobs.json', 'rb') as f:
    data = f.read()

# Check bytes around 968
print(f"Bytes 960-1000:")
chunk = data[960:1000]
print(f"HEX: {' '.join(f'{b:02X}' for b in chunk)}")
print(f"STR: {chunk.decode('utf-8', errors='replace')}")

# Also check bytes around 1099 (our fix position)
print(f"\nBytes 1095-1105:")
chunk = data[1095:1105]
print(f"HEX: {' '.join(f'{b:02X}' for b in chunk)}")
print(f"STR: {chunk.decode('utf-8', errors='replace')}")
