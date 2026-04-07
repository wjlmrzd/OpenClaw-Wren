#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import io, sys, json
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r"D:\OpenClaw\.openclaw\workspace\cron\jobs.json", "rb") as f:
    raw = f.read()

with open(r"D:\OpenClaw\.openclaw\workspace\cron\jobs.json", "r", encoding="utf-8-sig") as f:
    data = json.load(f)

targets = ['姣忔棩鏃╂姤', '閭\ue1bb欢鐩戞帶', '妯″瀷浣跨敤鎶ュ憡', '鏅氶棿鎻愰啋', '姣忓懆鎬荤粨']

for j in data['jobs']:
    n = j['name']
    for t in targets:
        if t in n or n in t:
            print(f"Found: {repr(n)} -> id {j['id']}")
            # Find in raw
            try:
                encoded = n.encode('utf-8')
                idx = raw.find(encoded)
                if idx >= 0:
                    print(f"  raw pos {idx}: {raw[idx-10:idx+len(encoded)+10].hex()}")
            except:
                pass
