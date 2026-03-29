#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import io, sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

file_path = r"D:\OpenClaw\.openclaw\workspace\cron\jobs.json"

with open(file_path, "rb") as f:
    raw = f.read()

# Find lines around 357 (0-indexed 356)
lines_raw = raw.split(b'\n')
for i in range(354, 361):
    b = lines_raw[i]
    try:
        t = b.decode('utf-8')
    except:
        t = b.decode('latin-1')
    print(f"Line {i+1} ({len(b)} bytes): {repr(t[:200])}")

# Also find all non-ASCII sequences that look like Chinese but might be wrong
print("\n--- Scanning for known garbled patterns in UTF-8 bytes ---")
garbled_map = [
    (b'\xe6\xb1\xba\xe5\x91\xbd\xe5\x8d\x8f\xe8\xb0\x90\xe5\x91\x98', "任务协调员"),
    (b'\xe6\x97\xa5\xe5\xbf\x97\xe6\xb8\x85\xe7\x90\x86\xe5\x91\x98', "日志清理员"),
    (b'\xe9\x85\x8d\xe7\xbd\xae\xe5\xae\xa1\xe8\xae\xa1\xe5\x91\x98', "配置审计员"),
    (b'\xe8\xb5\x84\xe6\xba\x90\xe5\xae\x88\xe6\x8a\xa4\xe8\x80\x85', "资源守护者"),
    (b'\xe7\x81\xbe\xe9\x9b\xbb\xe6\x81\xa2\xe5\xa4\x8d\xe5\x91\x98', "灾难恢复员"),
    (b'\xe9\x94\x99\xe8\xaf\xaf\xe6\x81\xa2\xe5\xa4\x8d\xe5\x91\x98', "错误恢复员"),
]

for pattern, correct in garbled_map:
    if pattern in raw:
        print(f"FOUND {correct} at: {[i for i in range(len(raw)) if raw[i:i+len(pattern)]==pattern]}")
