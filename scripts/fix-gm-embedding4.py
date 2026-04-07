f = open(r'D:\OpenClaw\.openclaw\openclaw.json', 'r', encoding='utf-8')
raw = f.read()
f.close()

# Find the bad sequence right after dedupThreshold
bad1 = '}},"embedding"'
idx1 = raw.find(bad1)
print(f'Bad1 at: {idx1}')
if idx1 > 0:
    print(repr(raw[idx1:idx1+30]))

# Find the bad ending
bad2 = '}},"lossless'
idx2 = raw.find(bad2)
print(f'Bad2 at: {idx2}')
if idx2 > 0:
    print(repr(raw[idx2:idx2+50]))
