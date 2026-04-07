import json
import os

fpath = os.path.join(os.environ['OPENCLAW_WORKSPACE'], '..', 'openclaw.json')
with open(fpath, 'r', encoding='utf-8') as f:
    raw = f.read()

# Check if already correct
if '"embedding"' in raw and 'text-embedding-v2' in raw and '"dimensions":512' in raw:
    # Check it's not the malformed version
    if '},},\n                                                                  },\n                                                                    "embedding"' not in raw:
        print("Already correct, skipping")
    else:
        print("Found malformed version, fixing...")
        # Remove the extra closing braces and fix structure
        # The malformed part ends with: "dimensions":512}},}}
        # Should end with: "dimensions":512
        bad = '                                                                    },"embedding":{"apiKey":"${DASHSCOPE_API_KEY}","baseURL":"https://dashscope.aliyuncs.com/v1/embeddings","model":"text-embedding-v2","dimensions":512}},}}'
        good = '                                                                    },\n                                                                    "embedding": {\n                                                                        "apiKey": "${DASHSCOPE_API_KEY}",\n                                                                        "baseURL": "https://dashscope.aliyuncs.com/v1/embeddings",\n                                                                        "model": "text-embedding-v2",\n                                                                        "dimensions": 512\n                                                                    }\n                                                                }'
        raw = raw.replace(bad, good)
        with open(fpath, 'w', encoding='utf-8', newline='') as f:
            f.write(raw)
        print("Fixed")
else:
    print("embedding not found, applying patch...")
    # Parse and patch properly
    data = json.loads(raw)
    
    embed_config = {
        "apiKey": "${DASHSCOPE_API_KEY}",
        "baseURL": "https://dashscope.aliyuncs.com/v1/embeddings",
        "model": "text-embedding-v2",
        "dimensions": 512
    }
    
    data['plugins']['entries']['graph-memory']['config']['embedding'] = embed_config
    
    # Write back with same formatting style (tabs)
    with open(fpath, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent='\t', ensure_ascii=False)
        f.write('\n')
    print("Applied via JSON patch")
