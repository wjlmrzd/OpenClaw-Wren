#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Final targeted fix for cron/jobs.json garbled names"""
import io, sys, json
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

file_path = r"D:\OpenClaw\.openclaw\workspace\cron\jobs.json"

with open(file_path, "rb") as f:
    raw = f.read()

# The known garbled patterns (8 UTF-8 chars = 24 bytes, then 3 more garbled bytes, then '?,\n')
# From diagnostic output:
# pos 13302: \xe6\xb5\xa0\xe8\xaf\xb2\xe5\xa7\x9f\xe9\x8d\x97\xe5\xbf\x9a\xe7\x9a\x9f\xe9\x8d\x9b?,\n
# Let me find all occurrences of '?,\n' and check what precedes them
print("=== All garbled name entries ===")
fixes_needed = []
i = 0
while i < len(raw):
    idx = raw.find(b'?,\n', i)
    if idx == -1:
        break
    # Check: is this preceded by a "name": " within 100 bytes?
    prefix_start = raw.rfind(b'"name": "', max(0, idx-100), idx)
    if prefix_start >= 0:
        val_bytes = raw[prefix_start + 8:idx + 3]  # after "name": "
        # Count valid UTF-8 Chinese chars (3-byte sequences)
        chars = []
        j = 0
        while j < len(val_bytes) - 1:
            if val_bytes[j] == 0xEF and j + 2 < len(val_bytes) and val_bytes[j+1] == 0xBF and val_bytes[j+2] == 0xBD:
                # U+FFFD replacement character - definitely garbled
                chars.append('\ufffd')
                j += 3
            elif val_bytes[j] >= 0xE4:  # 3-byte UTF-8 (Chinese chars start at E4)
                if j + 2 < len(val_bytes):
                    try:
                        c = val_bytes[j:j+3].decode('utf-8')
                        chars.append(c)
                        j += 3
                    except:
                        chars.append('?')
                        j += 1
                else:
                    j += 1
            elif val_bytes[j] == ord('?'):
                chars.append('?')
                j += 1
            else:
                chars.append(chr(val_bytes[j]) if val_bytes[j] >= 32 else f'\\x{val_bytes[j]:02x}')
                j += 1
        print(f"  pos {idx}: {''.join(chars)}")
        fixes_needed.append((prefix_start, idx, val_bytes, raw[idx-3:idx+3]))
    i = idx + 1

print(f"\nTotal garbled entries: {len(fixes_needed)}")

# Now fix each one
# Map of prefix bytes to correct name
# pos 13302: 灾难恢复员 (corrupted: 任务协调员??)
# pos 15087: 错误恢复员
# pos 21359: same as 15087
# pos 19698: same as 15087  
# pos 16716: 日志清理员 (fixed earlier)

# Actually, let me decode the prefixes to figure out what they should be
print("\n=== Decoding prefixes ===")
for prefix_start, idx, val_bytes, context in fixes_needed:
    print(f"\nContext bytes: {repr(context)}")
    # Try to decode as UTF-8, replacing errors
    try:
        decoded = val_bytes.decode('utf-8', errors='replace')
        print(f"  Decoded (replace): {decoded}")
    except:
        print(f"  Failed to decode")
    
    # Also try Latin-1
    try:
        latin1 = val_bytes.decode('latin-1', errors='replace')
        print(f"  Decoded (latin-1): {latin1}")
    except:
        pass
    
    # Print raw bytes of the name value
    print(f"  Raw ({len(val_bytes)} bytes): {val_bytes.hex()}")
    
    # Count 3-byte UTF-8 sequences
    count = 0
    for j in range(0, len(val_bytes)-2, 3):
        b = val_bytes[j:j+3]
        if b[0] >= 0xE0:  # Valid 3-byte UTF-8 start
            count += 1
    print(f"  3-byte UTF-8 sequences: {count}")
