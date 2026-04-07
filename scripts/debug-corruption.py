import json
import re

fpath = r'D:\OpenClaw\.openclaw\openclaw.json'

with open(fpath, 'r', encoding='utf-8-sig') as f:
    raw = f.read()

# Find the bad pattern
idx = raw.find('"dimensions":512')
if idx >= 0:
    print(f'dimensions marker at {idx}')
    print(repr(raw[idx:idx+50]))

# Find all '}},' patterns
for m in re.finditer(r'人对', raw):
    pass  # placeholder

# Simple search for the bad ending
bad = '}},\n                                                     },\n                                    "los'
good_idx = raw.find('"lossless-claw"')
print(f'lossless-claw at: {good_idx}')
if good_idx >= 0:
    print(repr(raw[good_idx-200:good_idx]))
