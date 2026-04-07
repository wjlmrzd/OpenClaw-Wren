f = open(r'D:\OpenClaw\.openclaw\openclaw.json', 'r', encoding='utf-8')
raw = f.read()
f.close()

# Find all occurrences of '}}' followed by a comma or brace
import re
matches = [(m.start(), m.group()) for m in re.finditer(r'}}{2,}', raw)]
print(f'Found {len(matches)} double-brace sequences')
for pos, m in matches[:5]:
    print(f'  pos {pos}: {repr(raw[pos-20:pos+30])}')

# Also find embedding area
idx = raw.find('"embedding"')
print(f'\\nembedding at: {idx}')
if idx > 0:
    print(repr(raw[idx:idx+100]))
