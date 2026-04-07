import json

fpath = r'D:\OpenClaw\.openclaw\openclaw.json'
with open(fpath, 'r', encoding='utf-8') as f:
    raw = f.read()

# The malformed part after embedding object
bad_ending = '"dimensions":512}},}}\n                        '
good_ending = '"dimensions": 512\n                                                                    }\n                                                                }\n'

# Check if the bad pattern exists
marker = '"dimensions":512'
idx = raw.find(marker)
if idx == -1:
    print('marker not found')
    exit(1)

end_part = raw[idx:idx+30]
print(f'Ending part: {repr(end_part)}')

# Also check the dedupThreshold area
dedup_idx = raw.find('"dedupThreshold"')
print(f'dedup at: {dedup_idx}, marker at: {idx}')
print(f'Between: {repr(raw[dedup_idx:dedup_idx+200])}')
