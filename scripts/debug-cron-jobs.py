#!/usr/bin/env python3
"""Debug cron-jobs.json - find exact problematic byte."""
import os, json

fp = r"D:\OpenClaw\.openclaw\workspace\memory\cron-jobs.json"

with open(fp, 'rb') as f:
    raw = f.read()

bom = bytes([0xef, 0xbb, 0xbf])
has_bom = raw[:3] == bom
content_bytes = raw[3:] if has_bom else raw

# Find any byte that's a "bare" continuation byte (0x80-0xBF) not following a lead byte
# OR a bare lead byte (0xC0-0xFF) that's not part of a valid sequence
i = 0
problems = []
while i < len(content_bytes):
    b = content_bytes[i]
    if b < 0x80:
        i += 1
        continue
    elif 0x80 <= b <= 0xBF:
        problems.append((i, b, 'bare continuation byte'))
        i += 1
    elif 0xC0 <= b <= 0xC1:
        problems.append((i, b, 'overlong/illegal lead'))
        i += 1
    elif 0xC2 <= b <= 0xDF:
        if i+1 < len(content_bytes) and 0x80 <= content_bytes[i+1] <= 0xBF:
            i += 2
        else:
            problems.append((i, b, '2-byte seq incomplete'))
            i += 1
    elif 0xE0 <= b <= 0xEF:
        if i+2 < len(content_bytes) and all(0x80 <= content_bytes[i+j] <= 0xBF for j in [1,2]):
            i += 3
        else:
            problems.append((i, b, '3-byte seq incomplete'))
            i += 1
    elif 0xF0 <= b <= 0xF4:
        if i+3 < len(content_bytes) and all(0x80 <= content_bytes[i+j] <= 0xBF for j in [1,2,3]):
            i += 4
        else:
            problems.append((i, b, '4-byte seq incomplete'))
            i += 1
    else:
        problems.append((i, b, 'illegal byte'))
        i += 1

print(f"Total bytes: {len(content_bytes)}")
print(f"Problem bytes found: {len(problems)}")
for pos, byte, reason in problems[:20]:
    ctx = content_bytes[max(0,pos-10):pos+20]
    print(f"  pos={pos} byte=0x{byte:02X} {reason}: hex={ctx.hex()} text={ctx.decode('utf-8', errors='replace')}")
