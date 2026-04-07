#!/usr/bin/env python3
"""Find exact char at position 994 in cron-jobs.json."""
import os, unicodedata

fp = r"D:\OpenClaw\.openclaw\workspace\memory\cron-jobs.json"

with open(fp, 'rb') as f:
    raw = f.read()

bom = bytes([0xef, 0xbb, 0xbf])
has_bom = raw[:3] == bom
content_bytes = raw[3:] if has_bom else raw
content = content_bytes.decode('utf-8')

pos = 994
c = content[pos]
print(f"Char at pos {pos}: U+{ord(c):04X} repr={repr(c)} cat={unicodedata.category(c)}")

# Show chars 985-1010
print("\nChars 985-1010:")
for i in range(985, min(1010, len(content))):
    c = content[i]
    print(f"  {i}: U+{ord(c):04X} cat={unicodedata.category(c)} repr={repr(c)}")
