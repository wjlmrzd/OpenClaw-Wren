#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import io, sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

file_path = r"D:\OpenClaw\.openclaw\workspace\cron\jobs.json"

with open(file_path, "rb") as f:
    raw = f.read()

# Find the garbled area: look for sequence near line 357
# "name": "浠诲姟鍗忚皟鍛?,\n
# Find position of 'name": "' near line 357
target = b'"name": "'
positions = []
for i in range(len(raw)):
    if raw[i:i+len(target)] == target:
        positions.append(i)

print(f"Found {len(positions)} occurrences of {repr(target)}")
for p in positions[-5:]:  # Show last 5
    # Show next 50 bytes
    snippet = raw[p:p+50]
    print(f"  pos {p}: {repr(snippet)}")
