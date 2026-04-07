import json

fpath = r'D:\OpenClaw\.openclaw\openclaw.json'
with open(fpath, 'r', encoding='utf-8') as f:
    raw = f.read()

# Find the malformed area - look for the doubled closing braces after dimensions
marker = '"dimensions":512'
idx = raw.find(marker)
if idx == -1:
    print('marker not found')
    exit(1)

end_idx = idx + len(marker)
print(f'Found marker at position {idx}')
print(f'After marker: {repr(raw[end_idx:end_idx+20])}')

# The malformed part: "dimensions":512}},}}
# We need to replace "dimensions":512}},}} with "dimensions":512\n                                                                }}
# But the correct JSON should have the embedding object inserted properly

# Check context
start_idx = max(0, idx - 100)
print(f'Context: {repr(raw[start_idx:end_idx+30])}')
