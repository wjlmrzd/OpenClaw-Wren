#!/usr/bin/env python3
"""Find the exact character causing json.loads to fail."""
import os, json, json as json_mod

fp = r"D:\OpenClaw\.openclaw\workspace\memory\cron-jobs.json"

with open(fp, 'rb') as f:
    raw = f.read()

bom = bytes([0xef, 0xbb, 0xbf])
has_bom = raw[:3] == bom
content_bytes = raw[3:] if has_bom else raw

# Decode with strict mode (will raise on invalid UTF-8)
try:
    content = content_bytes.decode('utf-8')
    print("UTF-8 decode OK")
except UnicodeDecodeError as e:
    print(f"Unicode error: {e}")
    content = content_bytes.decode('utf-8', errors='replace')
    print(f"Used replace mode")

# Find illegal control characters in strings
# Parse JSON manually to find them
import re

# Find all string values and check for control chars
illegal_positions = []
for i, c in enumerate(content):
    code = ord(c)
    if code < 0x20 and code not in (0x09, 0x0a, 0x0d):
        illegal_positions.append((i, code, repr(c)))
        if len(illegal_positions) >= 10:
            break

print(f"Illegal control chars found: {len(illegal_positions)}")
for pos, code, char_repr in illegal_positions:
    ctx_start = max(0, pos - 30)
    ctx_end = min(len(content), pos + 30)
    print(f"  pos={pos} code=0x{code:02X} char={char_repr}")
    print(f"  context: {repr(content[ctx_start:ctx_end])}")

# Try json.loads with custom parse
lines = content.split('\n')
if len(lines) >= 35:
    line35 = lines[34]  # 0-indexed
    print(f"\nLine 35 length: {len(line35)}")
    print(f"Line 35: {repr(line35[:100])}")
    for i, c in enumerate(line35[:60]):
        code = ord(c)
        if code < 0x20 and code not in (0x09, 0x0a, 0x0d):
            print(f"  Illegal ctrl at col {i}: 0x{code:02X}")
