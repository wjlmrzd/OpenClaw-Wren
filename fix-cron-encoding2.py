#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json
import io
import sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

file_path = r"D:\OpenClaw\.openclaw\workspace\cron\jobs.json"

with open(file_path, "r", encoding="utf-8-sig") as f:
    content = f.read()

# Find the exact issue
lines = content.split('\n')
for i in range(350, 365):
    print(f"{i+1}: {lines[i]}")

# Count all �? patterns
garbled = [(i+1, lines[i]) for i in range(len(lines)) if '�?' in lines[i] or '\ufffd' in lines[i]]
print(f"\nLines with �: {len(garbled)}")
for ln, lc in garbled:
    print(f"  Line {ln}: {repr(lc[:200])}")
