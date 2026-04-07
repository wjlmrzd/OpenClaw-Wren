#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fix garbled job names in cron/jobs.json"""
import io, sys, json
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

file_path = r"D:\OpenClaw\.openclaw\workspace\cron\jobs.json"

with open(file_path, "rb") as f:
    raw = f.read()

# Exact garbled patterns and their correct replacements (from diagnostic)
# Each garbled pattern is: [valid UTF-8 chars from corrupted encoding] + \x3f\x2c\x0a
garbled_to_correct = {
    # 灾难恢复员 (pos 13302)
    b'\xe6\xb5\xa0\xe8\xaf\xb2\xe5\xa7\x9f\xe9\x8d\x97\xe5\xbf\x9a\xe7\x9a\x9f\xe9\x8d\x9b\x3f\x2c\x0a': 
        '\u707e\u96be\u6062\u590d\u5458",\n'.encode('utf-8'),
    # 错误恢复员 (pos 15087, 21376)
    b'\xe9\x96\xbf\xe6\xac\x92\xee\x87\xa4\xe9\x8e\xad\xe3\x88\xa0\xee\x98\xb2\xe7\x80\xb9\x3f\x2c\x0a':
        '\u9519\u8bef\u6062\u590d\u5458",\n'.encode('utf-8'),
    # 日志清理员 (pos 16746)
    b'\xe9\x8f\x83\xe3\x83\xa5\xe7\xb9\x94\xe5\xa8\x93\xe5\x91\xaf\xe6\x82\x8a\xe9\x8d\x9b\x3f\x2c\x0a':
        '\u65e5\u5fd7\u6e05\u7406\u5458",\n'.encode('utf-8'),
    # 配置审计员 (pos 18160)
    b'\xe9\x96\xb0\xe5\xb6\x87\xe7\x96\x86\xe7\x80\xb9\xc2\xa4\xee\x85\xb8\xe7\x94\xaf\x3f\x2c\x0a':
        '\u914d\u7f6e\u5ba1\u8ba1\u5458",\n'.encode('utf-8'),
    # 资源守护者 (pos 19728)
    b'\xe7\x92\xa7\xe5\x8b\xac\xe7\xb0\xae\xe7\x80\xb9\xe5\xa0\x9f\xe5\xa7\xa2\xe9\x91\xb0\x3f\x2c\x0a':
        '\u8d44\u6e90\u5b88\u62a4\u8005",\n'.encode('utf-8'),
    # 错误恢复员 (pos 21376 - same as 15087)
    b'\xe9\x90\x8f\xe9\xb9\x83\xe6\xaf\xa4\xe9\x8e\xad\xe3\x88\xa0\xee\x98\xb2\xe7\x80\xb9\x3f\x2c\x0a':
        '\u9519\u8bef\u6062\u590d\u5458",\n'.encode('utf-8'),
}

fixed = raw
count = 0
for garbled, correct in garbled_to_correct.items():
    if garbled in fixed:
        fixed = fixed.replace(garbled, correct)
        print(f"FIXED: {garbled[:30].hex()} -> {correct[:30]}")
        count += 1
    else:
        print(f"NOT FOUND: {garbled[:30].hex()}")

print(f"\nApplied {count} fixes")

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
            print(f"STILL GARBLED: {name}")
    
    # Save
    with open(file_path, "wb") as f:
        f.write(fixed)
    print(f"Saved to {file_path}")
    
    # Print all job names
    print("\n=== All job names ===")
    for job in data.get('jobs', []):
        print(f"  {job.get('name', '???')}")
        
except json.JSONDecodeError as e:
    print(f"JSON FAILED: {e}")
    pos = e.pos
    lines = text.split('\n')
    line_no = text[:pos].count('\n')
    print(f"Error at line {line_no+1}, col {pos - text.rfind(chr(10), 0, pos)}")
    for i in range(max(0, line_no-2), min(len(lines), line_no+3)):
        print(f"  {i+1}: {repr(lines[i][:120])}")
