#!/usr/bin/env python3
"""Fix remaining PowerShell encoding issues."""
import os
import re

workspace = r"D:\OpenClaw\.openclaw\workspace"

files_to_fix = {
    r"D:\OpenClaw\.openclaw\workspace\scripts\analyze-crons.ps1": [
        ("-Path '", " -Encoding UTF8 -Path '"),
    ],
    r"D:\OpenClaw\.openclaw\workspace\scripts\fix-calendar.ps1": [
        ("Get-Content (Join-Path ", "Get-Content (Join-Path "),
    ],
}

for path, fixes in files_to_fix.items():
    if not os.path.exists(path):
        print(f"NOT FOUND: {path}")
        continue
    with open(path, "r", encoding="utf-8-sig", errors="replace") as f:
        content = f.read()
    original = content
    for old, new in fixes:
        if old in content:
            content = content.replace(old, new)
    if content != original:
        with open(path, "w", encoding="utf-8", newline="") as f:
            f.write(content)
        rel = path.replace(workspace, "~").replace("\\", "/")
        print(f"Fixed: {rel}")

# Now fix fix-calendar.ps1 Get-Content calls (they read Obsidian JSON without -Encoding)
calendar = r"D:\OpenClaw\.openclaw\workspace\scripts\fix-calendar.ps1"
if os.path.exists(calendar):
    with open(calendar, "r", encoding="utf-8-sig", errors="replace") as f:
        content = f.read()
    original = content
    # Fix: Get-Content (Join-Path ...) without -Encoding
    def add_encoding(m):
        prefix = m.group(1)  # "Get-Content (Join-Path "
        rest = m.group(2)     # the path expr
        pipe = m.group(3)    # the pipe
        if '-Encoding' not in (prefix + rest):
            return prefix + rest + ' -Encoding UTF8' + pipe
        return m.group(0)
    
    content = re.sub(
        r'(Get-Content\s+(\([^\)]+\))\s*(\|))',
        add_encoding,
        content,
        flags=re.IGNORECASE
    )
    if content != original:
        with open(calendar, "w", encoding="utf-8", newline="") as f:
            f.write(content)
        print(f"Fixed: {calendar.replace(workspace, '~').replace(chr(92), '/')}")

print("Done")
