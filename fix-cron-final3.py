#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fix remaining 7 garbled job names in cron/jobs.json"""
import io, sys, json
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r"D:\OpenClaw\.openclaw\workspace\cron\jobs.json", "rb") as f:
    raw = f.read()

# The 7 garbled entries and their correct replacements
# Each entry: (garbled_hex, correct_name, correct_hex)
fixes = [
    # 1. 姣忔棩鏃╂姤 -> 每日早报
    ("e5a7a3e5bf94e6a3a9e98f83e29582e5a7a4",
     "每日早报",
     "e697a5e5bf97e68a8fe68a8f"),
    # 2. 鏅氶棿鎻愰啋 -> 晚间提醒
    ("e98f85e6b0b6e6a3bfe98ebbe684b0e5958b",
     "晚间提醒",
     "e699aee997b4e68a90e6989de794a3"),
    # 3. 姣忓懆鎬荤粨 -> 每周总结
    ("e5a7a3e5bf93e68786e98eace88da4e7b2a8",
     "每周总结",
     "e696b4e699aee68d8be7bb9ae68a89"),
    # 4. 閭�欢鐩戞帶 -> 邮件监控 (ee86bb = U+E1BB Private Use)
    ("e996adee86bbe6aca2e990a9e6889ee5b8b6",
     "邮件监控",
     "e99fb7e4bbb6e76d86e68f8de7a081"),
    # 5. Workspace 澶囦唤 -> Workspace 备份 (57 6f 72 6b 73 70 61 63 65 20 + Chinese)
    ("576f726b737061636520e6beb6e59ba6e594a4",
     "Workspace 备份",
     "576f726b737061636520e59058e4bb95"),
    # 6. 妯″瀷浣跨敤鎶ュ憡 -> 模型使用报告
    ("e5a6afe280b3e780b7e6b5a3e8b7a8e695a4e98eb6e383a5e686a1",
     "模型使用报告",
     "e6a8a1e58f8fe4bdae794a8e588bde8a681"),
    # 7. OpenClaw 杩愯惀鎬荤洃 -> OpenClaw 运营总监
    ("4f70656e436c617720e69da9e684afe68380e98eace88da4e6b483",
     "OpenClaw 运营总监",
     "4f70656e436c617720e8bf90e84283e694bfe7a791"),
    # 8. 椤圭洰椤鹃棶 -> 项目顾问
    ("e6a4a4e59cade6b4b0e6a4a4e9b983e6a3b6",
     "项目顾问",
     "e9a18ce79a84e9a1a7e98085"),
]

fixed = bytearray(raw)
count = 0

for garbled_hex, correct_name, correct_hex in fixes:
    garbled_bytes = bytes.fromhex(garbled_hex)
    correct_bytes = bytes.fromhex(correct_hex)
    
    idx = raw.find(garbled_bytes)
    if idx >= 0:
        # Replace: remove garbled, insert correct
        before = bytes(fixed[:idx])
        after = bytes(fixed[idx + len(garbled_bytes):])
        fixed = bytearray(before + correct_bytes + after)
        print(f"FIXED: {garbled_hex[:30]}... ({len(garbled_bytes)} bytes) -> {correct_name} ({len(correct_bytes)} bytes)")
        count += 1
    else:
        print(f"NOT FOUND: {garbled_hex[:30]}...")

print(f"\nApplied {count}/{len(fixes)} fixes")

# Verify JSON
print("\n--- Verifying JSON ---")
try:
    text = fixed.decode("utf-8")
    data = json.loads(text)
    print(f"JSON OK: {len(data.get('jobs', []))} jobs")
    
    # Print all job names
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
