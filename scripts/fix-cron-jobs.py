#!/usr/bin/env python3
"""Fix cron-jobs.json with illegal control characters at byte level."""
import os, json

fp = r"D:\OpenClaw\.openclaw\workspace\memory\cron-jobs.json"
size = os.path.getsize(fp)
print(f"File size: {size}")

with open(fp, 'rb') as f:
    raw = f.read()

bom = bytes([0xef, 0xbb, 0xbf])
has_bom = raw[:3] == bom
print(f"BOM: {has_bom}")

content_bytes = raw[3:] if has_bom else raw

# Decode ignoring invalid UTF-8 bytes
content = content_bytes.decode('utf-8', errors='ignore')
print(f"Content length after ignoring bad bytes: {len(content)}")

# Try parse
try:
    data = json.loads(content)
    print(f"Parse OK: {len(data.get('jobs', []))} jobs")
except json.JSONDecodeError as e:
    print(f"JSON error at pos {e.pos}")
    pos = e.pos
    ctx_start = max(0, pos - 50)
    ctx_end = min(len(content), pos + 100)
    print(f"Context: {repr(content[ctx_start:ctx_end])}")
    
    # Try to find what's at that position in raw bytes
    if has_bom:
        byte_pos = pos + 3  # account for BOM
    else:
        byte_pos = pos
    print(f"Raw bytes around error (byte {byte_pos}): {content_bytes[max(0,byte_pos-5):byte_pos+10].hex()}")
