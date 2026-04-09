#!/usr/bin/env python3
"""Session archiver - archives recent messages from main session JSONL to memory/sessions/"""

import json, os, sys
from datetime import datetime, timezone, timedelta
from pathlib import Path

def main():
    hours = 48
    openclaw_dir = Path(os.environ.get('OPENCLAW_DIR', r'D:\OpenClaw\.openclaw'))
    sessions_json = openclaw_dir / 'agents' / 'main' / 'sessions' / 'sessions.json'
    out_dir = openclaw_dir / 'memory' / 'sessions'
    
    if not sessions_json.exists():
        print(f"sessions.json not found: {sessions_json}")
        return
    
    with open(sessions_json, 'r', encoding='utf-8') as f:
        sessions = json.load(f)
    
    main_session = sessions.get('agent:main:main', {})
    session_file = main_session.get('sessionFile')
    if not session_file or not Path(session_file).exists():
        print(f"sessionFile not found: {session_file}")
        return
    
    cutoff = datetime.now(timezone.utc) - timedelta(hours=hours)
    new_messages = []
    
    with open(session_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
            except:
                continue
            if entry.get('type') != 'message':
                continue
            
            ts_str = entry.get('timestamp')
            if not ts_str:
                continue
            try:
                ts = datetime.fromisoformat(ts_str.replace('Z', '+00:00'))
            except:
                continue
            
            if ts < cutoff:
                continue
            
            msg = entry.get('message', {})
            role = msg.get('role', '')
            if role == 'system':
                continue
            
            content = msg.get('content', '')
            texts = []
            if isinstance(content, list):
                for part in content:
                    if part.get('type') == 'text' and part.get('text'):
                        texts.append(part['text'])
                    elif part.get('type') == 'thinking' and part.get('thinking'):
                        think = part['thinking'][:100]
                        texts.append(f"[thinking: {think}...]")
            else:
                texts.append(str(content)) if content else None
            
            text = ' '.join(t for t in texts if t)
            if not text:
                continue
            
            new_messages.append({
                'ts': ts.strftime('%Y-%m-%d %H:%M:%S'),
                'role': role,
                'content': text
            })
    
    print(f"Found {len(new_messages)} messages in last {hours}h")
    if not new_messages:
        return
    
    out_dir.mkdir(parents=True, exist_ok=True)
    date_str = datetime.now().strftime('%Y-%m-%d')
    out_file = out_dir / f'{date_str}.jsonl'
    
    # Deduplicate by ts
    existing_ts = set()
    if out_file.exists():
        with open(out_file, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line:
                    try:
                        existing_ts.add(json.loads(line).get('ts'))
                    except:
                        pass
    
    count = 0
    with open(out_file, 'a', encoding='utf-8') as f:
        for msg in sorted(new_messages, key=lambda x: x['ts']):
            if msg['ts'] not in existing_ts:
                f.write(json.dumps(msg, ensure_ascii=False) + '\n')
                count += 1
    
    with open(out_file, 'r', encoding='utf-8') as f:
        total = sum(1 for _ in f)
    
    print(f"Archived {count} new messages to {out_file} ({total} total lines)")

if __name__ == '__main__':
    main()
