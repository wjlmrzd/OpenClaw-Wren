#!/usr/bin/env python3
"""Fix PowerShell scripts that read JSON without -Encoding UTF8."""
import os
import re

workspace = r"D:\OpenClaw\.openclaw\workspace"

scripts_to_fix = [
    r"D:\OpenClaw\.openclaw\workspace\scripts\regression-test-runner.ps1",
    r"D:\OpenClaw\.openclaw\workspace\scripts\config-audit-check.ps1",
    r"D:\OpenClaw\.openclaw\workspace\scripts\list-cron-jobs.ps1",
    r"D:\OpenClaw\.openclaw\workspace\scripts\list-cron-models.ps1",
    r"D:\OpenClaw\.openclaw\workspace\scripts\analyze-crons.ps1",
    r"D:\OpenClaw\.openclaw\workspace\scripts\update-notif-state.ps1",
    r"D:\OpenClaw\.openclaw\workspace\scripts\temp_check.ps1",
]

fixed_files = []

for path in scripts_to_fix:
    if not os.path.exists(path):
        continue
    with open(path, "r", encoding="utf-8-sig", errors="replace") as f:
        content = f.read()

    original = content

    # Fix 1: Get-Content "path" -Raw | -> Get-Content "path" -Raw -Encoding UTF8 |
    # Handles: Get-Content "path\to\some.json" -Raw | ConvertFrom-Json
    content = re.sub(
        r'(Get-Content\s+)("([^"]+\.json)"|(\'[^\']+\.json\'))(\s+-Raw)?(\s*\|)',
        lambda m: (
            m.group(1) + (m.group(2) or m.group(3) or m.group(4))
            + (m.group(5) or '')
            + ' -Encoding UTF8'
            + m.group(6)
        ),
        content,
        flags=re.IGNORECASE
    )

    # Fix 2: Get-Content $VAR -Raw | -> Get-Content $VAR -Raw -Encoding UTF8 |
    content = re.sub(
        r'(Get-Content\s+)(\$[\w]+)(\s+-Raw)?(\s*\|)',
        lambda m: m.group(1) + m.group(2) + (m.group(3) or '') + ' -Encoding UTF8' + m.group(4),
        content,
        flags=re.IGNORECASE
    )

    # Fix 3: bare Get-Content "path" | ...without -Encoding -> add -Encoding
    # Match Get-Content "path.json" | ... (ConvertFrom-Json etc) without -Encoding already
    # This catches the case where there's no -Raw but has a pipe
    content = re.sub(
        r'(Get-Content\s+)("([^"]+\.json)"|(\'[^\']+\.json\'))(\s+-Raw)?( *\|)',
        lambda m: (
            m.group(1) + (m.group(2) or m.group(3) or m.group(4))
            + (m.group(5) or '')
            + ' -Encoding UTF8'
            + m.group(6)
        ),
        content,
        flags=re.IGNORECASE
    )

    if content != original:
        with open(path, "w", encoding="utf-8", newline="") as f:
            f.write(content)
        rel = path.replace(workspace, "~").replace("\\", "/")
        fixed_files.append(rel)
        # Show what changed
        orig_lines = original.split('\n')
        new_lines = content.split('\n')
        for i, (o, n) in enumerate(zip(orig_lines, new_lines)):
            if o != n:
                print(f"  {rel}:{i+1}")
                print(f"    OLD: {o.strip()[:120]}")
                print(f"    NEW: {n.strip()[:120]}")

print(f"\nTotal scripts fixed: {len(fixed_files)}")
