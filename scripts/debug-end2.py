fpath = r'D:\OpenClaw\.openclaw\openclaw.json'
with open(fpath, 'r', encoding='utf-8-sig') as f:
    raw = f.read()

print(f"Total length: {len(raw)}")
print(f"Ending 500 chars:")
print(repr(raw[-500:]))
print()

# Count opening and closing braces
opens = raw.count('{')
closes = raw.count('}')
print(f"Opening braces: {opens}, Closing braces: {closes}, Diff: {opens-closes}")
