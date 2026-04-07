#!/usr/bin/env python3
"""Find the malformed name field in cron-jobs.json."""
import os

fp = r"D:\OpenClaw\.openclaw\workspace\memory\cron-jobs.json"

with open(fp, 'rb') as f:
    raw = f.read()

bom = bytes([0xef, 0xbb, 0xbf])
has_bom = raw[:3] == bom
content_bytes = raw[3:] if has_bom else raw

# Search for the byte sequence of "🏥 健康监控" in raw bytes
target = "🏥 健康监控".encode('utf-8')
target_hex = target.hex()
print(f"Searching for: {target_hex}")

pos = content_bytes.find(target)
if pos >= 0:
    print(f"Found at byte offset {pos}")
    # Show 50 bytes around it
    snippet = content_bytes[pos:pos+60]
    print(f"Raw bytes: {snippet.hex()}")
    print(f"Decoded: {snippet.decode('utf-8', errors='replace')}")
    
    # Also show as ASCII escape
    ascii_repr = ''.join(chr(b) if 32 <= b < 127 else f'\\x{b:02x}' for b in snippet)
    print(f"Ascii escape: {ascii_repr}")
