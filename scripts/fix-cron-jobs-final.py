#!/usr/bin/env python3
"""Clean cron-jobs.json by removing illegal control chars and re-save."""
import os, json, re

fp = r"D:\OpenClaw\.openclaw\workspace\memory\cron-jobs.json"

with open(fp, 'rb') as f:
    raw = f.read()

bom = bytes([0xef, 0xbb, 0xbf])
has_bom = raw[:3] == bom
content_bytes = raw[3:] if has_bom else raw

# Decode UTF-8 strictly
try:
    content = content_bytes.decode('utf-8')
    print("UTF-8 strict decode: OK")
except UnicodeDecodeError as e:
    print(f"UTF-8 strict decode failed: {e}")
    # Replace bad bytes
    content = content_bytes.decode('utf-8', errors='replace')
    print("Used errors='replace'")

print(f"Content length: {len(content)}")

# Strip illegal control characters (keep \t, \n, \r only)
# This regex matches control chars 0x00-0x08, 0x0b, 0x0c, 0x0e-0x1f
clean = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f]', '', content)
print(f"Cleaned length: {len(clean)}")

# Try parse
try:
    data = json.loads(clean)
    print(f"Parse OK: {len(data.get('jobs', []))} jobs")
    
    # Save clean
    with open(fp, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    new_size = os.path.getsize(fp)
    with open(fp, 'rb') as f:
        new_raw = f.read()
    new_bom = new_raw[:3] == bom
    print(f"Saved: size={new_size}, BOM={new_bom}, starts={new_raw[:6].hex()}")
    
except json.JSONDecodeError as e:
    print(f"Parse failed: {e}")
    pos = e.pos
    ctx = clean[max(0,pos-50):pos+100]
    print(f"Context: {repr(ctx)}")
