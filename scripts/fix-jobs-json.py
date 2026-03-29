# -*- coding: utf-8 -*-
import re
import json

# Read the file
with open(r'D:\OpenClaw\.openclaw\workspace\cron\jobs.json', 'r', encoding='utf-8-sig') as f:
    content = f.read()

# Fix corrupted name fields - patterns like "name": "...?,
# The pattern is: missing closing quote before comma
# Replace pattern: "name": "CORRUPTED_TEXT?,
# With: "name": "CORRECTED_TEXT",

fixes = {
    r'"name": "鏃ュ巻妫€鏌?,': '"name": "日历检查",',
    r'"name": "浠诲姟鍗忚皟锻炼?,': '"name": "任务协调员",',
    r'"name": "閿欒.*鎭①.*瀹?,': '"name": "错误恢复员",',
    r'"name": "鏃ュ織娓呯悊锻炼?,': '"name": "日志清理员",',
    r'"name": "閰嶇疆.*甯?,': '"name": "配置审计员",',
    r'"name": "璧勬簮.*?,': '"name": "资源守护者",',
    r'"name": "zalaling.*?,': '"name": "灾难恢复官",',
}

# Apply fixes using regex
for pattern, replacement in fixes.items():
    # Use regex for more flexible matching
    regex_pattern = pattern.replace('.*', '[^"]+')
    content = re.sub(regex_pattern, replacement, content)

# Also fix any remaining patterns with missing closing quotes
# Pattern: "name": "...something?,
# Fix by adding the missing quote
content = re.sub(r'"name": "([^"]+),\s*\n', r'"name": "\1",\n', content)

# Verify JSON is valid
try:
    data = json.loads(content)
    print(f"JSON is valid. {len(data['jobs'])} jobs found.")
    
    # Check for any remaining corruption
    for job in data['jobs']:
        name = job.get('name', '')
        if '\ufffd' in name or name.endswith(',') and not name.endswith('",'):
            print(f"WARNING: Still corrupted: {name}")
        else:
            print(f"OK: {name}")
    
    # Write the fixed file
    with open(r'D:\OpenClaw\.openclaw\workspace\cron\jobs.json', 'w', encoding='utf-8-sig') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print("File saved successfully.")
    
except json.JSONDecodeError as e:
    print(f"JSON still invalid: {e}")
