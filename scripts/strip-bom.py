#!/usr/bin/env python3
"""Strip BOM from JSON files and re-save."""
import os, json

workspace = r"D:\OpenClaw\.openclaw\workspace"

files = [
    r"D:\OpenClaw\.openclaw\workspace\memory\cron-jobs.json",
    r"D:\OpenClaw\.openclaw\workspace\memory\cron-list.json",
    r"D:\OpenClaw\.openclaw\workspace\memory\test-git.json",
]

for fp in files:
    size = os.path.getsize(fp)
    with open(fp, 'rb') as f:
        raw = f.read()

    bom = bytes([0xef, 0xbb, 0xbf])
    has_bom = raw[:3] == bom
    print(f"{os.path.basename(fp)}: size={size}, BOM={has_bom}")

    if has_bom:
        content_bytes = raw[3:]
        try:
            content = content_bytes.decode('utf-8')
            data = json.loads(content)
            jobs_count = len(data.get('jobs', []))
            print(f"  Parse OK: {jobs_count} jobs, re-saving...")

            # Write back clean UTF-8 NO BOM
            with open(fp, 'wb') as f:
                f.write(content.encode('utf-8'))

            new_size = os.path.getsize(fp)
            with open(fp, 'rb') as f:
                new_raw = f.read()
            new_bom = new_raw[:3] == bom
            print(f"  New size={new_size}, BOM={new_bom}, starts={new_raw[:6].hex()}")
        except Exception as e:
            print(f"  ERROR: {e}")
            # Try with errors=replace
            try:
                content = content_bytes.decode('utf-8', errors='replace')
                data = json.loads(content)
                print(f"  Parse OK (replace mode): {len(data.get('jobs',[]))} jobs")
                with open(fp, 'wb') as f:
                    f.write(content.encode('utf-8'))
                print(f"  Written with replace mode")
            except Exception as e2:
                print(f"  FALLBACK ERROR: {e2}")
