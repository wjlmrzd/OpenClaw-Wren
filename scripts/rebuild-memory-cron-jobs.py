#!/usr/bin/env python3
"""Rebuild memory/cron-jobs.json from cron/jobs.json (clean source)."""
import os, json

src = r"D:\OpenClaw\.openclaw\workspace\cron\jobs.json"
dst = r"D:\OpenClaw\.openclaw\workspace\memory\cron-jobs.json"
dst2 = r"D:\OpenClaw\.openclaw\workspace\memory\cron-list.json"
dst3 = r"D:\OpenClaw\.openclaw\workspace\memory\test-git.json"

for dst_file in [dst, dst2, dst3]:
    # Read from clean source
    with open(src, 'r', encoding='utf-8', errors='replace') as f:
        content = f.read()
    # Strip BOM if present
    if content.startswith('\ufeff'):
        content = content[1:]
    data = json.loads(content)
    print(f"Source ({os.path.basename(src)}): {len(data.get('jobs',[]))} jobs")
    
    # Add timestamp
    from datetime import datetime
    data['_rebuilt'] = datetime.now().isoformat()
    
    # Write clean UTF-8 NO BOM
    with open(dst_file, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    new_size = os.path.getsize(dst_file)
    with open(dst_file, 'rb') as f:
        new_raw = f.read()
    has_bom = new_raw[:3] == bytes([0xef, 0xbb, 0xbf])
    print(f"  -> {os.path.basename(dst_file)}: {new_size} bytes, BOM={has_bom}")

# Verify parse
for dst_file in [dst, dst2, dst3]:
    try:
        with open(dst_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        print(f"  VERIFY OK: {os.path.basename(dst_file)}: {len(data.get('jobs',[]))} jobs")
    except Exception as e:
        print(f"  VERIFY FAILED: {os.path.basename(dst_file)}: {e}")
