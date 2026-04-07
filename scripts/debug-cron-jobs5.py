#!/usr/bin/env python3
"""Find the problematic section in cron-jobs.json raw bytes."""
import os

fp = r"D:\OpenClaw\.openclaw\workspace\memory\cron-jobs.json"

with open(fp, 'rb') as f:
    raw = f.read()

bom = bytes([0xef, 0xbb, 0xbf])
has_bom = raw[:3] == bom
content_bytes = raw[3:] if has_bom else raw

# Search for "e5b195" which is the UTF-8 for Chinese char "健"
# Actually, let's just scan and print the WHOLE thing line by line
lines = content_bytes.split(b'\n')
print(f"Total lines: {len(lines)}")
for i, line in enumerate(lines[30:40], 31):  # lines 31-40
    try:
        decoded = line.decode('utf-8')
        print(f"Line {i}: {repr(decoded[:120])}")
    except UnicodeDecodeError as e:
        print(f"Line {i}: DECODE ERROR {e}")
        print(f"  Hex: {line[:100].hex()}")
        replaced = line.decode('utf-8', errors='replace')
        print(f"  Replaced: {repr(replaced[:100])}")
