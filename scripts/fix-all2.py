import json

fpath = r'D:\OpenClaw\.openclaw\openclaw.json'

with open(fpath, 'r', encoding='utf-8-sig') as f:
    raw = f.read()

# Fix 1: Remove backtick before dedupThreshold
if '\x60"dedup' in raw:
    raw = raw.replace('\x60"dedup', '"dedup')
    print("Fixed backtick")

# Fix 2: Fix the malformed closing section after "dimensions":512
# The malformed section ends with: "dimensions":512}},}}
# After that comes a newline then "lossless-claw"
# We need to replace: "dimensions":512}},}}
# with: "dimensions":512\n                                                                    }\n                                                                }
# (properly closes the embedding object and the config object)

old_ending = '"dimensions":512}},}}\n                        '
new_ending = '"dimensions": 512\n                                                                    }\n                                                                }\n'

if old_ending in raw:
    raw = raw.replace(old_ending, new_ending)
    print("Fixed dimensions closing")
else:
    print("Old ending not found exactly, trying alternative...")
    # Try with different whitespace
    import re
    # Match "dimensions":512 then two or more } then newline
    pattern = r'"dimensions":512}{2,},?\n\s*"loss'
    match = re.search(pattern, raw)
    if match:
        print(f"Found via regex at {match.start()}: {repr(match.group())}")
        # Replace with correct
        correct = '"dimensions": 512\n                                                                }\n                                    '
        raw = raw[:match.start()] + correct + raw[match.end():]
        print("Fixed via regex")
    else:
        print("Could not find pattern to fix")

# Now try to parse
try:
    data = json.loads(raw)
    print("JSON is now valid!")
    gm_config = data['plugins']['entries']['graph-memory']['config']
    if 'embedding' in gm_config:
        print("Embedding config:", gm_config['embedding'])
    else:
        print("No embedding in config, adding...")
        gm_config['embedding'] = {
            "apiKey": "${DASHSCOPE_API_KEY}",
            "baseURL": "https://dashscope.aliyuncs.com/v1/embeddings",
            "model": "text-embedding-v2",
            "dimensions": 512
        }
    with open(fpath, 'w', encoding='utf-8-sig', newline='') as f:
        f.write(json.dumps(data, indent='\t', ensure_ascii=False))
        f.write('\n')
    print("Written successfully!")
except json.JSONDecodeError as e:
    print(f"Still invalid: {e}")
    pos = e.pos
    print(f"Error at char {pos}: {repr(raw[max(0,pos-50):pos+50])}")
