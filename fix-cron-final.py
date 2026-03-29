#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fix garbled job names in cron/jobs.json - FINAL VERSION"""
import io, sys, json
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

file_path = r"D:\OpenClaw\.openclaw\workspace\cron\jobs.json"

with open(file_path, "rb") as f:
    raw = f.read()

# Find all "name": entries that end with ?, 
target = b'"name": "'
positions = []
for i in range(len(raw)):
    if raw[i:i+len(target)] == target:
        positions.append(i)

print(f"Found {len(positions)} name entries")

# Map of garbled byte sequences -> correct Chinese name
# Each garbled entry has the pattern: [8 garbled Chinese chars]?,\n
# Manually identified from the last 5 positions:
# pos 15057: 浠诲姟鍗忚皟鍛?,
# pos 16716: ? (different)
# pos 18131: ? (different)
# pos 19698: ? (different)
# pos 21346: ? (different)

# Strategy: For each "name" entry, if it ends with '?,\n', 
# it's garbled. Replace the whole name value with a placeholder.
# Then fix the specific ones we know.

garbled_replacements = {
    # From the actual byte positions we found
    b'\xe9\x96\xbf\xe6\xac\x92\xee\x87\xa4\xe9\x8e\xad\xe3\x88\xa0\xee\x98\xb2': '\u4efb\u52a1\u534f\u8c03\u5458',  # 任务协调员
    b'\xe9\x8f\x83\xe3\x83\xa5\xe7\xb9\x94\xe5\xa8\x93\xe5\x91\xaf\xe6\x82\x8a\xe9\x8d\x9b': '\u65e5\u5fd7\u6e05\u7406\u5458',  # 日志清理员
    b'\xe9\x96\xb0\xe5\xb6\x87\xe7\x96\x86\xe7\x80\xb9\xc2\xa4\xee\x85\xb8\xe7\x94\xaf': '\u914d\u7f6e\u5ba1\u8ba1\u5458',  # 配置审计员
    b'\xe7\x92\xa7\xe5\x8b\xac\xe7\xb0\xae\xe7\x80\xb9\xe5\xa0\x9f\xe5\xa7\xa2\xe9\x91\xb0': '\u8d44\u6e90\u5b88\u62a4\u8005',  # 资源守护者
    b'\xe9\x90\x8f\xe9\xb9\x83\xe6\xaf\xa4\xe9\x8e\xad\xe3\x88\xa0\xee\x98\xb2\xe7\x80\xb9': '\u707e\u96be\u6062\u590d\u5458',  # 灾难恢复员
    # The 6th one we haven't seen yet...
}

# For all the ones we CAN identify, fix them
# Also fix generic ?,\n pattern for remaining
fixed = raw
count = 0
for garbled_bytes, correct_name in garbled_replacements.items():
    if garbled_bytes in fixed:
        # Replace garbled sequence + '?,\n' with correct name + '",\n'
        replacement = (correct_name + '",\n').encode('utf-8')
        target_seq = garbled_bytes + b'?,\n'
        if target_seq in fixed:
            fixed = fixed.replace(target_seq, replacement)
            print(f"FIXED: {correct_name}")
            count += 1
        else:
            print(f"WARNING: garbled bytes found but not followed by '?,\\n'")

# Now fix the remaining ones generically
# Pattern: any sequence of bytes that looks like valid UTF-8 leading bytes + '?,\n'
# But actually let's just read the JSON and fix from there

# Read as text (ignore errors) and try to parse
text = fixed.decode('utf-8', errors='replace')

# Now find and fix remaining '?,\n' patterns in name fields
import re

# Pattern: "name": "...?,\n" where ... is any text
def fix_name(match):
    name_field = match.group(0)
    # Check if it ends with ?,
    if '?,' in name_field:
        # Extract the garbled prefix
        prefix_start = name_field.index('": "') + 3
        prefix = name_field[prefix_start:]
        if prefix.endswith('?,\n'):
            garbled = prefix[:-3]  # remove '?,\n'
            print(f"Garbled name field: {repr(garbled[:50])}")
    return name_field

# Actually, let's just do a targeted replacement
# The remaining garbled names are likely of the form:
# "\xe4\xbb\xbb\xe5\x8a\xa1\xe5\x8d\x8f\xe8\xb0\xa8\xe5\x91\x98" + corrupted + "?\n"
# which should be "任务协调员"

# Let's try a different approach: read the raw bytes, find all instances of
# a 3-byte UTF-8 sequence followed by ?, and replace them

# Actually let me just directly find and replace the specific known patterns
# by scanning through the file

# Scan through raw bytes and find all '?,\n' sequences preceded by valid UTF-8
print("\n--- Scanning for remaining garbled entries ---")
i = 0
while i < len(fixed):
    idx = fixed.find(b'?,\n', i)
    if idx == -1:
        break
    # Check if preceded by a "name": " prefix (within 100 bytes)
    prefix_start = fixed.rfind(b'"name": "', max(0, idx-100), idx)
    if prefix_start >= 0:
        garbled_val = fixed[prefix_start + 8:idx + 3]  # after "name": "
        print(f"Found garbled at pos {idx}: {repr(garbled_val[:60])}")
    i = idx + 1

# Now let's do the replacement
# We know the pattern: [valid UTF-8 chars that look like Chinese] + ?,\n
# Let me find and replace the specific remaining garbled entries
# by looking at what we found above

# For now, let's just try to load the JSON and see if it's valid
print("\n--- Trying to parse JSON ---")
try:
    data = json.loads(fixed)
    print(f"SUCCESS: {len(data.get('jobs', []))} jobs loaded")
except json.JSONDecodeError as e:
    print(f"FAILED: {e}")
    # Show the area around the error
    pos = e.pos
    lines = fixed.split('\n')
    line_no = fixed[:pos].count('\n')
    print(f"Error at line {line_no+1}")
    for i in range(max(0, line_no-2), min(len(lines), line_no+3)):
        print(f"  {i+1}: {repr(lines[i][:100])}")
