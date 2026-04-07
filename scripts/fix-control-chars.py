#!/usr/bin/env python3
"""Fix JSON files with illegal control characters."""
import os, json, re

workspace = r"D:\OpenClaw\.openclaw\workspace"

files = [
    r"D:\OpenClaw\.openclaw\workspace\memory\cron-jobs.json",
    r"D:\OpenClaw\.openclaw\workspace\memory\cron-list.json",
    r"D:\OpenClaw\.openclaw\workspace\memory\test-git.json",
]

def fix_json_control_chars(content):
    """Remove illegal control characters from JSON string."""
    # JSON allows \t (0x09), \n (0x0a), \r (0x0d) - all others 0x00-0x1f are illegal
    # Replace with space or remove
    def replace_char(m):
        c = ord(m.group(0))
        if c in (0x09, 0x0a, 0x0d):  # allowed
            return chr(c)
        elif c < 0x20:  # illegal control char
            return ' '  # replace with space
        else:
            return chr(c)
    
    # First unescape any incorrectly escaped sequences
    # Then replace remaining illegal control chars
    fixed = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f]', replace_char, content)
    return fixed

for fp in files:
    size = os.path.getsize(fp)
    with open(fp, 'rb') as f:
        raw = f.read()

    bom = bytes([0xef, 0xbb, 0xbf])
    has_bom = raw[:3] == bom
    content_bytes = raw[3:] if has_bom else raw

    # Decode
    try:
        content = content_bytes.decode('utf-8')
    except UnicodeDecodeError:
        content = content_bytes.decode('utf-8', errors='replace')

    # Fix control chars
    fixed_content = fix_json_control_chars(content)

    # Try parse
    try:
        data = json.loads(fixed_content)
        print(f"OK: {os.path.basename(fp)}, jobs={len(data.get('jobs',[]))}")
        
        # Write back clean
        with open(fp, 'w', encoding='utf-8', newline='\n') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        new_size = os.path.getsize(fp)
        with open(fp, 'rb') as f:
            new_raw = f.read()
        new_bom = new_raw[:3] == bom
        print(f"  Fixed and re-saved: size {size}->{new_size}, BOM={new_bom}")
    except json.JSONDecodeError as e:
        print(f"FAILED {os.path.basename(fp)}: {e}")
        # Show context
        pos = e.pos
        print(f"  Context: ...{fixed_content[max(0,pos-30):pos+50]}...")
