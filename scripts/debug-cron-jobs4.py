#!/usr/bin/env python3
"""Search for hospital emoji in raw bytes."""
import os

fp = r"D:\OpenClaw\.openclaw\workspace\memory\cron-jobs.json"

with open(fp, 'rb') as f:
    raw = f.read()

bom = bytes([0xef, 0xbb, 0xbf])
has_bom = raw[:3] == bom
content_bytes = raw[3:] if has_bom else raw

# Search for the 4-byte hospital emoji sequence F0 9F 8F A5
target = bytes([0xF0, 0x9F, 0x8F, 0xA5])
pos = content_bytes.find(target)
print(f"Hospital emoji found at byte offset: {pos}")

if pos >= 0:
    # Show 80 bytes around it
    snippet = content_bytes[pos:pos+80]
    print(f"Around emoji ({pos}-{pos+80}):")
    print(f"  Hex: {snippet.hex()}")
    # Decode with replace
    decoded = snippet.decode('utf-8', errors='replace')
    print(f"  Decoded: {repr(decoded)}")
    
    # Find line number
    line_count = content_bytes[:pos].count(b'\n') + 1
    print(f"  Approx line: {line_count}")
    
    # Find position IN the line
    last_newline = content_bytes[:pos].rfind(b'\n')
    col = pos - last_newline
    print(f"  Approx column: {col}")
