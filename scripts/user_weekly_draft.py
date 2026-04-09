#!/usr/bin/env python3
"""Generate USER.md weekly update draft from recent conversations."""

import json, os, sys
from pathlib import Path
from datetime import datetime, timedelta, timezone as tz

def main():
    days = 7
    openclaw_dir = Path(os.environ.get('OPENCLAW_DIR', r'D:\OpenClaw\.openclaw'))
    sessions_json = openclaw_dir / 'agents' / 'main' / 'sessions' / 'sessions.json'
    out_file = openclaw_dir / 'workspace' / 'memory' / 'user_update_pending.md'
    
    if not sessions_json.exists():
        print(f"sessions.json not found: {sessions_json}")
        return
    
    with open(sessions_json, 'r', encoding='utf-8') as f:
        sessions = json.load(f)
    
    main_session = sessions.get('agent:main:main', {})
    session_file = main_session.get('sessionFile')
    if not session_file or not Path(session_file).exists():
        print(f"sessionFile not found")
        return
    
    cutoff = datetime.now(tz.utc) - timedelta(days=days)
    user_messages = []
    
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
            
            msg = entry.get('message', {})
            if msg.get('role') != 'user':
                continue
            
            ts_str = entry.get('timestamp')
            if not ts_str:
                continue
            try:
                ts = datetime.fromisoformat(ts_str.replace('Z', '+00:00')).astimezone()
            except:
                continue
            
            if ts.astimezone(tz.utc) < cutoff:
                continue
            
            content = msg.get('content', '')
            texts = []
            if isinstance(content, list):
                for part in content:
                    if part.get('type') == 'text' and part.get('text'):
                        texts.append(part['text'])
            else:
                if content:
                    texts.append(str(content))
            
            text = ' '.join(texts)
            if text:
                user_messages.append(f"[{ts.strftime('%m-%d %H:%M')}] {text[:200]}")
    
    if not user_messages:
        print("No recent user messages found")
        return
    
    recent = user_messages[-20:]  # last 20
    today = datetime.now().strftime('%Y-%m-%d')
    
    content = f"""# USER.md Update Draft - {today}

## 本周 Wren 的主要互动（最近 20 条）
{chr(10).join(recent)}

---
**操作建议**：对比当前 USER.md，将本周新增的偏好、习惯、或重要反馈更新进去。
"""
    
    out_file.parent.mkdir(parents=True, exist_ok=True)
    with open(out_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Draft written to {out_file} ({len(user_messages)} messages from last {days} days)")

if __name__ == '__main__':
    main()
