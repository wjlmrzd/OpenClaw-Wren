fpath = r'D:\OpenClaw\.openclaw\openclaw.json'
with open(fpath, 'r', encoding='utf-8-sig') as f:
    raw = f.read()

pos = 31606
print(f"Around error position {pos}:")
print(repr(raw[pos-100:]))
print(f"\nTotal length: {len(raw)}")
print(f"Ending: {repr(raw[-100:])}")
