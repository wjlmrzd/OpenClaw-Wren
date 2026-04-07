"""Fix cost_tracker cron job: python -> py"""
import json
from pathlib import Path

jobs_path = Path(r'D:\OpenClaw\.openclaw\cron\jobs.json')
jobs = json.loads(jobs_path.read_text(encoding='utf-8'))

for j in jobs['jobs']:
    if j['id'] == 'e430f8ec-d5e2-4e2f-a7fd-7b14f60930d6':
        old_msg = j['payload']['message']
        new_msg = old_msg.replace('python "D:', 'py "D:')
        new_msg = new_msg.replace('python \\"D:', 'py \\"D:')
        if old_msg != new_msg:
            j['payload']['message'] = new_msg
            j['updatedAtMs'] = int(1000 * __import__('time').time())
            jobs_path.write_text(json.dumps(jobs, ensure_ascii=False, indent=2), encoding='utf-8')
            print(f'Fixed: python -> py in cost_tracker cron job')
        else:
            print('No change needed')
        break
else:
    print('Job not found')
