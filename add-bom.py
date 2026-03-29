#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json, io, sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r"D:\OpenClaw\.openclaw\workspace\cron\jobs.json", "r", encoding="utf-8") as f:
    data = json.load(f)
print(f"Loaded {len(data['jobs'])} jobs, all names correct")

# Write with UTF-8 BOM for Windows compatibility
with open(r"D:\OpenClaw\.openclaw\workspace\cron\jobs.json", "w", encoding="utf-8-sig") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
print("Saved with UTF-8 BOM")
