#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Remove double BOM and save clean JSON"""
import io, sys, json
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r"D:\OpenClaw\.openclaw\workspace\cron\jobs.json", "rb") as f:
    raw = f.read()

print(f"File size: {len(raw)} bytes")
print(f"First 10 bytes: {raw[:10].hex()}")

# Remove BOM(s) from start
stripped = raw
while stripped.startswith(b'\xef\xbb\xbf'):
    stripped = stripped[3:]
    print("Removed one BOM")

print(f"After BOM removal: {len(stripped)} bytes")
print(f"First 10 bytes: {stripped[:10].hex()}")

# Validate JSON
try:
    text = stripped.decode("utf-8")
    data = json.loads(text)
    print(f"\nJSON OK: {len(data['jobs'])} jobs")
    for j in data['jobs']:
        print(f"  {j['name']}")
    
    # Save without BOM (clean JSON)
    with open(r"D:\OpenClaw\.openclaw\workspace\cron\jobs.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"\nSaved clean (no BOM)!")
    
except json.JSONDecodeError as e:
    print(f"\nJSON FAILED: {e}")
