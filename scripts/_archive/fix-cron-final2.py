#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fix garbled job names in cron/jobs.json - with BOM removal"""
import io, sys, json
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

file_path = r"D:\OpenClaw\.openclaw\workspace\cron\jobs.json"

with open(file_path, "rb") as f:
    raw = f.read()

# Remove BOM if present
if raw.startswith(b'\xef\xbb\xbf'):
    print("Removing UTF-8 BOM")
    raw = raw[3:]

# The garbled patterns: [8 UTF-8 Chinese chars, then 3 corrupted bytes, then '?,\n']
# After replacement: [correct 8 Chinese chars + closing quote + comma + newline]
garbled_to_correct = {
    # 灾难恢复员 (pos ~13302)
    # garbled: e6b5a0 e8afb2 e5a79f e98d97 e5bf9a e79a9f e98d9b 3f2c0a
    b'\xe6\xb5\xa0\xe8\xaf\xb2\xe5\xa7\x9f\xe9\x8d\x97\xe5\xbf\x9a\xe7\x9a\x9f\xe9\x8d\x9b\x3f\x2c\x0a':
        '\u707e\u96be\u6062\u590d\u5458",\n'.encode('utf-8'),
    # 错误恢复员 (pos ~15087 and ~21376)
    # garbled: e996bf e6ac92 ee87a4 e98ead e388a0 ee98b2 e780b9 3f2c0a
    b'\xe9\x96\xbf\xe6\xac\x92\xee\x87\xa4\xe9\x8e\xad\xe3\x88\xa0\xee\x98\xb2\xe7\x80\xb9\x3f\x2c\x0a':
        '\u9519\u8bef\u6062\u590d\u5458",\n'.encode('utf-8'),
    # 日志清理员 (pos ~16746)
    # garbled: e98f83 e383a5 e7b994 e5a893 e591af e6828a e98d9b 3f2c0a
    b'\xe9\x8f\x83\xe3\x83\xa5\xe7\xb9\x94\xe5\xa8\x93\xe5\x91\xaf\xe6\x82\x8a\xe9\x8d\x9b\x3f\x2c\x0a':
        '\u65e5\u5fd7\u6e05\u7406\u5458",\n'.encode('utf-8'),
    # 配置审计员 (pos ~18160)
    # garbled: e996b0 e5b687 e79686 e780b9 c2a4 ee85b8 e794af 3f2c0a
    b'\xe9\x96\xb0\xe5\xb6\x87\xe7\x96\x86\xe7\x80\xb9\xc2\xa4\xee\x85\xb8\xe7\x94\xaf\x3f\x2c\x0a':
        '\u914d\u7f6e\u5ba1\u8ba1\u5458",\n'.encode('utf-8'),
    # 资源守护者 (pos ~19728)
    # garbled: e792a7 e58bac e7b0ae e780b9 e5a09f e5a7a2 e991b0 3f2c0a
    b'\xe7\x92\xa7\xe5\x8b\xac\xe7\xb0\xae\xe7\x80\xb9\xe5\xa0\x9f\xe5\xa7\xa2\xe9\x91\xb0\x3f\x2c\x0a':
        '\u8d44\u6e90\u5b88\u62a4\u8005",\n'.encode('utf-8'),
    # 错误恢复员 variant (pos ~21376)
    # garbled: e9908f e9b983 e6afa6 e98ead e388a0 ee98b2 e780b9 3f2c0a
    b'\xe9\x90\x8f\xe9\xb9\x83\xe6\xaf\xa6\xe9\x8e\xad\xe3\x88\xa0\xee\x98\xb2\xe7\x80\xb9\x3f\x2c\x0a':
        '\u9519\u8bef\u6062\u590d\u5458",\n'.encode('utf-8'),
}

fixed = raw
count = 0
not_found = []
for garbled, correct in garbled_to_correct.items():
    if garbled in fixed:
        fixed = fixed.replace(garbled, correct)
        print(f"FIXED: {garbled[:24].hex()} -> {correct.decode('utf-8', errors='replace')}")
        count += 1
    else:
        not_found.append(garbled.hex())
        print(f"NOT FOUND: {garbled[:24].hex()}")

print(f"\nApplied {count} fixes, {len(not_found)} not found")

# Verify JSON
print("\n--- Verifying JSON ---")
try:
    text = fixed.decode('utf-8')
    data = json.loads(text)
    print(f"JSON OK: {len(data.get('jobs', []))} jobs")
    
    # Check for remaining garbled
    for job in data.get('jobs', []):
        name = job.get('name', '')
        if '�' in name or '\ufffd' in name:
            print(f"STILL GARBLED: {repr(name)}")
    
    # Print all job names
    print("\n=== All job names ===")
    for job in data.get('jobs', []):
        print(f"  {job.get('name', '???')}")
    
    # Save with UTF-8 BOM (for AutoCAD compatibility)
    output = b'\xef\xbb\xbf' + fixed
    with open(file_path, "wb") as f:
        f.write(output)
    print(f"\nSaved to {file_path} ({len(output)} bytes)")
        
except json.JSONDecodeError as e:
    print(f"JSON FAILED: {e}")
    text = fixed.decode('utf-8', errors='replace')
    lines = text.split('\n')
    line_no = text[:e.pos].count('\n') if hasattr(e, 'pos') else 0
    print(f"Error around line {line_no+1}")
    for i in range(max(0, line_no-2), min(len(lines), line_no+3)):
        print(f"  {i+1}: {repr(lines[i][:120])}")
