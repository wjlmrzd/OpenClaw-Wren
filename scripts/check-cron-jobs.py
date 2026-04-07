#!/usr/bin/env python3
import json, os

fp = r'D:\OpenClaw\.openclaw\workspace\memory\cron-jobs.json'
size = os.path.getsize(fp)
with open(fp, 'rb') as f:
    raw = f.read()

bom_len = 3 if raw.startswith(b'\xef\xbb\xbf') else 0
content = raw[bom_len:].decode('utf-8', errors='replace')
enc_len = len(content.encode('utf-8'))
missing = size - bom_len - enc_len
print(f'File size: {size}, BOM: {bom_len}, Content chars: {len(content)}, UTF-8 bytes: {enc_len}, Missing: {missing}')

try:
    data = json.loads(content)
    print(f'Parse OK: {len(data.get("jobs", []))} jobs')
except Exception as e:
    print(f'Parse error: {e}')
