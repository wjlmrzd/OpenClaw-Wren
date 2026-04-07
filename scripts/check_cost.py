import json

f = open(r'D:\OpenClaw\.openclaw\workspace\memory\cost-tracker\store.json', encoding='utf-8')
d = json.load(f)

gt = d['globalTotal']
print(f"Global Total: {gt['totalCalls']} calls, {gt['totalTokens']:,} tokens, ${gt['totalCost']:.4f}")
print()
print("Top Sessions by tokens:")
sessions = sorted(d['sessions'].values(), key=lambda x: -x['totalTokens'])[:10]
for s in sessions:
    free_str = "free" if s['isFree'] else f"${s['totalCost']:.4f}"
    print(f"  {s['sessionKey'][:35]:35s} {s['totalCalls']:3d} calls {s['totalTokens']:>10,} tokens  {free_str}")
print()
print(f"Tracked files: {len(d.get('trackedFiles', {}))}")
