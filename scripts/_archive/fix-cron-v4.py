#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fix remaining garbled job names - use actual chars, not hex"""
import io, sys, json
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r"D:\OpenClaw\.openclaw\workspace\cron\jobs.json", "rb") as f:
    raw = f.read()

# Map: garbled_name -> correct_name
fixes = [
    ("姣忔棩鏃╂姤",       "每日早报"),
    ("鏅氶棿鎻愰啋",       "晚间提醒"),
    ("姣忓懆鎬荤粨",       "每周总结"),
    ("閭\ue1bb欢鐩戞帶",    "邮件监控"),
    ("Workspace 澶囦唤",   "Workspace 备份"),
    ("妯″瀷浣跨敤鎶ュ憡",  "模型使用报告"),
    ("OpenClaw 杩愯惀鎬荤洃", "OpenClaw 运营总监"),
    ("椤圭洰椤鹃棶",       "项目顾问"),
]

fixed = bytearray(raw)
count = 0

for garbled, correct in fixes:
    garbled_bytes = garbled.encode("utf-8")
    correct_bytes = correct.encode("utf-8")
    
    idx = fixed.find(garbled_bytes)
    if idx >= 0:
        before = bytes(fixed[:idx])
        after = bytes(fixed[idx + len(garbled_bytes):])
        fixed = bytearray(before + correct_bytes + after)
        print(f"FIXED: {garbled!r} ({len(garbled_bytes)}b) -> {correct!r} ({len(correct_bytes)}b)")
        count += 1
    else:
        print(f"NOT FOUND: {garbled!r}")

print(f"\nApplied {count}/{len(fixes)} fixes")

# Verify JSON
print("\n--- Verifying JSON ---")
try:
    text = fixed.decode("utf-8-sig")
    data = json.loads(text)
    print(f"JSON OK: {len(data.get('jobs', []))} jobs")
    
    print("\n=== All job names ===")
    for j in data.get('jobs', []):
        print(f"  {j.get('name', '???')}")
    
    # Save with BOM
    with open(r"D:\OpenClaw\.openclaw\workspace\cron\jobs.json", "wb") as f:
        f.write(b'\xef\xbb\xbf')
        f.write(fixed)
    print(f"\nSaved!")
    
except json.JSONDecodeError as e:
    print(f"JSON FAILED: {e}")
