#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import io, sys, json
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r"D:\OpenClaw\.openclaw\workspace\cron\jobs.json", "rb") as f:
    raw = f.read()

with open(r"D:\OpenClaw\.openclaw\workspace\cron\jobs.json", "r", encoding="utf-8-sig") as f:
    data = json.load(f)

# Find all name positions in raw
targets = ["每日早报", "晚间提醒", "每周总结", "邮件监控", "模型使用报告"]
target_bytes = [t.encode("utf-8") for t in targets]

print("=== Scanning raw for correct names ===")
for tb in target_bytes:
    idx = raw.find(tb)
    if idx >= 0:
        print(f"FOUND correct: {tb.decode()} at pos {idx}")
    else:
        print(f"NOT FOUND: {tb.decode()}")

# Find garbled positions
print("\n=== Scanning for garbled in raw ===")
for j in data["jobs"]:
    n = j["name"]
    # Check if name has non-CJK, non-ASCII chars
    bad_chars = [(i, c) for i, c in enumerate(n) if (0xAC00 <= ord(c) <= 0xD7AF)]
    if bad_chars or '�' in n or '\ufffd' in n:
        print(f"\nGarbled: {repr(n)}")
        try:
            nb = n.encode("utf-8")
            idx = raw.find(nb)
            if idx < 0:
                # Try without closing quote
                idx = raw.find(nb[:-1])
            print(f"  Pos: {idx}, Hex: {nb.hex()}")
            # Show context in raw
            if idx >= 0:
                print(f"  Raw: {raw[idx-5:idx+len(nb)+5].hex()}")
                print(f"  Raw chars: {raw[idx-5:idx+len(nb)+5]}")
        except Exception as e:
            print(f"  Error: {e}")
