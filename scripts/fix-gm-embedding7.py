import json

fpath = r'D:\OpenClaw\.openclaw\openclaw.json'
with open(fpath, 'r', encoding='utf-8-sig') as f:
    raw = f.read()

try:
    data = json.loads(raw)
    print("JSON is valid!")
    gm = data.get('plugins', {}).get('entries', {}).get('graph-memory', {}).get('config', {})
    print("graph-memory config:", json.dumps(gm, indent=2))
except json.JSONDecodeError as e:
    print(f"JSON invalid: {e}")
    pos = e.pos
    print(f"Error at position {pos}")
    print(repr(raw[max(0,pos-100):pos+100]))
