# -*- coding: utf-8 -*-
import re
import json
import sys

# Read the file
with open(r'D:\OpenClaw\.openclaw\workspace\cron\jobs.json', 'r', encoding='utf-8-sig') as f:
    content = f.read()

# Fix corrupted name fields using regex
# Pattern: "name": "...TEXT,<newline>" where TEXT doesn't end with quote
content = re.sub(
    r'"name": "([^"]+)(\s*),(\s*\n\s*"enabled")',
    r'"name": "\1"\2\3',
    content
)

# Verify JSON is valid
try:
    data = json.loads(content)
    sys.stderr.write(f"JSON is valid. {len(data['jobs'])} jobs found.\n")
    
    # Write the fixed file
    with open(r'D:\OpenClaw\.openclaw\workspace\cron\jobs.json', 'w', encoding='utf-8-sig') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    sys.stderr.write("File saved successfully.\n")
    
except json.JSONDecodeError as e:
    sys.stderr.write(f"JSON still invalid: {e}\n")
