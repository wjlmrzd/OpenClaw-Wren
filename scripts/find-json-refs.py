#!/usr/bin/env python3
"""Find JSON file references in PowerShell scripts."""
import os
import glob

workspace = r"D:\OpenClaw\.openclaw\workspace"
targets = ["cron-list.json", "test-git.json", "website-monitor-output.json"]

results = []
for path in glob.glob(os.path.join(workspace, "scripts", "*.ps1"), recursive=True):
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
        for i, line in enumerate(lines, 1):
            for t in targets:
                if t in line:
                    rel = path.replace(workspace, "~").replace("\\", "/")
                    results.append(f"{rel}:{i}: {line.rstrip()}")
    except:
        pass

if results:
    for r in results:
        print(r)
else:
    print("(none found)")
