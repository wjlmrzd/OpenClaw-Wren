#!/usr/bin/env python3
"""Fix cron-jobs.json using Latin-1 decode to preserve raw bytes."""
import os, json, re

workspace = r"D:\OpenClaw\.openclaw\workspace"

files = [
    r"D:\OpenClaw\.openclaw\workspace\memory\cron-jobs.json",
    r"D:\OpenClaw\.openclaw\workspace\memory\cron-list.json",
    r"D:\OpenClaw\.openclaw\workspace\memory\test-git.json",
]

def fix_latin1_json(content):
    """Decode Latin-1 bytes, remove/replace JSON-illegal chars, re-encode as UTF-8."""
    # Re-encode to get raw bytes
    try:
        raw_bytes = content.encode('latin-1', errors='replace')
    except Exception:
        return None, "encode failed"
    
    # Remove/replace JSON-illegal characters
    # In Latin-1 decoded string: 0x00-0x1F are control chars
    result = []
    for c in content:
        code = ord(c)
        if code in (0x09, 0x0A, 0x0D):
            # Allow \t \n \r
            result.append(c)
        elif 0x00 <= code < 0x20:
            # Illegal control -> skip
            result.append(' ')
        elif 0x7F <= code <= 0x9F:
            # High Latin-1 control chars (Windows-1252 controls) -> skip
            result.append(' ')
        elif 0xD800 <= code <= 0xDFFF:
            # Surrogates -> skip
            result.append('')
        elif code == 0xFFFD:
            # Replacement char -> skip
            result.append('')
        else:
            result.append(c)
    
    text = ''.join(result)
    return text, None

for fp in files:
    print(f"\n=== {os.path.basename(fp)} ===")
    size = os.path.getsize(fp)
    with open(fp, 'rb') as f:
        raw = f.read()

    bom = bytes([0xef, 0xbb, 0xbf])
    has_bom = raw[:3] == bom
    content_bytes = raw[3:] if has_bom else raw

    # Decode as Latin-1 (1:1 byte mapping)
    content = content_bytes.decode('latin-1', errors='replace')
    print(f"Length: {len(content)}")
    
    # Fix illegal chars
    clean, err = fix_latin1_json(content)
    if err:
        print(f"Error: {err}")
        continue
    
    try:
        data = json.loads(clean)
        jobs_count = len(data.get('jobs', []))
        print(f"Parse OK: {jobs_count} jobs, re-saving...")
        
        with open(fp, 'w', encoding='utf-8', newline='\n') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        new_size = os.path.getsize(fp)
        print(f"Done: {size} -> {new_size} bytes")
        
    except json.JSONDecodeError as e:
        print(f"Parse error: {e}")
        pos = e.pos
        ctx = clean[max(0,pos-50):pos+80]
        # Encode ctx to handle any display issues
        try:
            print(f"Context: {ctx.encode('ascii', errors='replace').decode('ascii')}")
        except:
            print(f"Context (raw): {repr(ctx[:100])}")
