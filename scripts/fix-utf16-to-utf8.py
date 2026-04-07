#!/usr/bin/env python3
"""Fix UTF-16 LE JSON files by converting to UTF-8."""
import os
import glob

workspace = r"D:\OpenClaw\.openclaw\workspace"
fixed = []

# Find all UTF-16 LE files
for path in glob.glob(os.path.join(workspace, "**", "*.json"), recursive=True):
    if "node_modules" in path or ".git" in path:
        continue
    try:
        with open(path, "rb") as f:
            raw = f.read()
        if raw.startswith(b'\xff\xfe'):
            rel = path.replace(workspace, "~").replace("\\", "/")
            print(f"UTF-16 LE: {rel}")
            # Decode as UTF-16 LE and write as UTF-8
            content = raw.decode("utf-16-le")
            with open(path, "w", encoding="utf-8", newline="") as f:
                f.write(content)
            fixed.append(rel)
            print(f"  -> Converted to UTF-8")
    except Exception as e:
        print(f"Error on {path}: {e}")

print(f"\nTotal fixed: {len(fixed)}")
for f in fixed:
    print(f"  {f}")
