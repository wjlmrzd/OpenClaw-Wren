import json

fpath = r'D:\OpenClaw\.openclaw\openclaw.json'

with open(fpath, 'r', encoding='utf-8-sig') as f:
    raw = f.read()

# Fix 1: Remove backtick before dedupThreshold
if '\x60"dedup' in raw:
    raw = raw.replace('\x60"dedup', '"dedup')
    print("Fixed backtick")

# Fix 2: Fix the malformed closing braces after "dimensions":512
# The bad pattern: "dimensions":512}},}} followed by newline and closing braces
# Look for the area
dims_idx = raw.find('"dimensions":512')
print(f"dimensions at: {dims_idx}")
if dims_idx >= 0:
    after = raw[dims_idx:dims_idx+60]
    print(f"After dimensions: {repr(after)}")

    # Find where it goes wrong: look for '}}' near 'dimensions'
    bad_patterns = ['}},}}', '}},}', '}}}}']
    for bp in bad_patterns:
        if bp in raw:
            print(f"Found bad pattern: {repr(bp)}")
            # Find where it starts
            pos = raw.find(bp)
            print(f"  at position {pos}, context: {repr(raw[pos-30:pos+40])}")

# Find the "lossless" section to understand the structure
lossless_idx = raw.find('"lossless-claw"')
if lossless_idx >= 0:
    print(f"lossless-claw at: {lossless_idx}")
    print(f"  before it: {repr(raw[lossless_idx-150:lossless_idx])}")
