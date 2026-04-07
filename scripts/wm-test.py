import sys
import json
from pathlib import Path
import requests

sys.stdout.reconfigure(encoding='utf-8')
sys.stderr.reconfigure(encoding='utf-8')

print('1. Loading config...', flush=True)
CONFIG_FILE = Path(r'D:\OpenClaw\.openclaw\workspace\scripts\website-monitor-config.json')
with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
    config = json.load(f)
print(f'   Config loaded: {len(config["websites"])} sites', flush=True)

print('2. Loading state...', flush=True)
STATE_FILE = Path(r'D:\OpenClaw\.openclaw\workspace\scripts\website-monitor-state.json')
with open(STATE_FILE, 'r', encoding='utf-8') as f:
    state = json.load(f)
print(f'   State loaded: {len(state.get("websites", {}))} tracked sites', flush=True)

print('3. Testing requests to first 3 sites...', flush=True)
for site in config['websites'][:3]:
    name = site['name']
    url = site['url']
    try:
        print(f'   Testing {name}...', end=' ', flush=True)
        resp = requests.get(url, timeout=15)
        print(f'{resp.status_code}', flush=True)
    except Exception as e:
        print(f'ERROR: {e}', flush=True)

print('Done.', flush=True)
