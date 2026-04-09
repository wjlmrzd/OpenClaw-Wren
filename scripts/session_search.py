#!/usr/bin/env python3
"""Search archived session messages."""

import json, os, sys, re
sys.stdout.reconfigure(encoding='utf-8', errors='replace')
from pathlib import Path
from datetime import datetime, timedelta

def main():
    query = None
    days = 7
    limit = 10
    
    # Parse args manually
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        arg = args[i]
        if arg in ('-Query', '--query', '-q'):
            query = args[i+1] if i+1 < len(args) else None
            i += 2
        elif arg in ('-Days', '--days', '-d'):
            days = int(args[i+1]) if i+1 < len(args) else 7
            i += 2
        elif arg in ('-Limit', '--limit', '-l'):
            limit = int(args[i+1]) if i+1 < len(args) else 10
            i += 2
        elif not arg.startswith('-') and query is None:
            query = arg
            i += 1
        else:
            i += 1
    
    if not query:
        print("Usage: session_search.py -Query 'keyword' [-Days 7] [-Limit 10]")
        return
    
    if not query:
        print("Usage: session_search.py -Query 'keyword' [-Days 7] [-Limit 10]")
        return
    
    openclaw_dir = Path(os.environ.get('OPENCLAW_DIR', r'D:\OpenClaw\.openclaw'))
    sessions_dir = openclaw_dir / 'memory' / 'sessions'
    
    if not sessions_dir.exists():
        print("No sessions archived yet")
        return
    
    cutoff = datetime.now() - timedelta(days=days)
    pattern = re.compile(query, re.IGNORECASE)
    results = []
    
    for jsonl_file in sorted(sessions_dir.glob('*.jsonl'), key=lambda x: -x.stat().st_mtime):
        if datetime.fromtimestamp(jsonl_file.stat().st_mtime) < cutoff:
            continue
        with open(jsonl_file, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    msg = json.loads(line)
                except:
                    continue
                content = msg.get('content', '')
                if pattern.search(content):
                    snippet = content[:200] + ('...' if len(content) > 200 else '')
                    results.append({
                        'file': jsonl_file.name,
                        'ts': msg.get('ts', ''),
                        'role': msg.get('role', ''),
                        'snippet': snippet
                    })
                    if len(results) >= limit:
                        break
        if len(results) >= limit:
            break
    
    if not results:
        print(f"No matches found for: {query}")
    else:
        print(f"=== Session Search: '{query}' ({len(results)} matches) ===")
        for r in results:
            print(f"\n[{r['ts']}] [{r['role']}]")
            print(r['snippet'])

if __name__ == '__main__':
    main()
