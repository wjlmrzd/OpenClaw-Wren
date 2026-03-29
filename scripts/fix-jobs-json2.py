# -*- coding: utf-8 -*-
import re
import json

# Read the file
with open(r'D:\OpenClaw\.openclaw\workspace\cron\jobs.json', 'r', encoding='utf-8-sig') as f:
    content = f.read()

# Count fixes before
before_count = content.count(',\n      "enabled"')

# Fix corrupted name fields
# Pattern: "name": "...something?, (missing closing quote)
content = re.sub(
    r'"name": "([^"]{1,50})?,\s*\n\s*"enabled"',
    lambda m: f'"name": "{m.group(1)}",\n      "enabled"',
    content
)

# Also fix any specific corrupted entries
corruptions = [
    ('鏃ュ巻妫€鏌?,', '日历检查",'),
    ('浠诲姟鍗忚皟锻炼?,', '任务协调员",'),
    ('閿欒', '错误恢复员",'),
    ('鏃ュ織娓呯悊锻炼?,', '日志清理员",'),
    ('閰嶇疆.*甯?,', '配置审计员",'),
    ('璧勬簮.*?,', '资源守护者",'),
    ('zalaling.*?,', '灾难恢复官",'),
]

# Use simpler approach - just fix the pattern of missing closing quotes
# Look for "name": "...TEXT,<newline>" where TEXT doesn't end with quote
lines = content.split('\n')
fixed_lines = []
for i, line in enumerate(lines):
    if '"name":' in line and ',"' not in line:
        # This line is missing the closing quote before the comma
        # Extract the name part
        match = re.search(r'"name":\s*"([^"]+)"?,', line)
        if match:
            name = match.group(1)
            # Fix it
            fixed_line = line.replace(f'"{name}",', f'"{name}",')
            fixed_lines.append(fixed_line)
            print(f"Fixed: {name[:20]}...")
        else:
            fixed_lines.append(line)
    else:
        fixed_lines.append(line)

content = '\n'.join(fixed_lines)

# Verify JSON is valid
try:
    data = json.loads(content)
    print(f"JSON is valid. {len(data['jobs'])} jobs found.")
    
    # Write the fixed file
    with open(r'D:\OpenClaw\.openclaw\workspace\cron\jobs.json', 'w', encoding='utf-8-sig') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print("File saved successfully.")
    
except json.JSONDecodeError as e:
    print(f"JSON still invalid: {e}")
    # Print the area around the error
    lines = content.split('\n')
    line_num = int(str(e).split('line ')[-1].split()[0]) - 1
    for i in range(max(0, line_num-2), min(len(lines), line_num+3)):
        print(f"{i+1}: {lines[i][:80]}")
