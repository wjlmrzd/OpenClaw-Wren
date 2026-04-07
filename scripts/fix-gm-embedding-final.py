import json

fpath = r'D:\OpenClaw\.openclaw\openclaw.json'

# Read with BOM handling
with open(fpath, 'r', encoding='utf-8-sig') as f:
    raw = f.read()

# Check if the backtick corruption exists
if '\x60"dedupThreshold"' in raw:
    print("Found backtick corruption, fixing...")
    # Remove the backtick before dedupThreshold
    raw = raw.replace('\x60"dedupThreshold"', '"dedupThreshold"')
    print("Backtick removed")

# Now parse and patch properly
try:
    data = json.loads(raw)
except json.JSONDecodeError as e:
    print(f"Still invalid after backtick fix: {e}")
    exit(1)

# Check current embedding config
gm_config = data['plugins']['entries']['graph-memory']['config']
print("Current graph-memory config keys:", list(gm_config.keys()))
if 'embedding' in gm_config:
    emb = gm_config['embedding']
    print("Embedding already set:", emb)
else:
    print("No embedding, adding...")
    gm_config['embedding'] = {
        "apiKey": "${DASHSCOPE_API_KEY}",
        "baseURL": "https://dashscope.aliyuncs.com/v1/embeddings",
        "model": "text-embedding-v2",
        "dimensions": 512
    }

# Write back with same tab indentation and BOM
with open(fpath, 'w', encoding='utf-8-sig', newline='') as f:
    # Custom dump to preserve tab formatting style
    f.write(json.dumps(data, indent='\t', ensure_ascii=False))
    f.write('\n')

print("Done! JSON written with BOM and tabs.")
