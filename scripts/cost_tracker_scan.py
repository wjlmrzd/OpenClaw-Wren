"""
cost_tracker_scan.py
从 session 文件中提取 usage 数据并写入 cost-tracker store
"""

import json
import os
from pathlib import Path

REPO = Path(os.environ.get('OPENCLAW_REPO', r'D:\OpenClaw\.openclaw'))
STORE_DIR = REPO / 'workspace' / 'memory' / 'cost-tracker'
STORE_FILE = STORE_DIR / 'store.json'
SESSIONS_DIR = REPO / 'agents' / 'main' / 'sessions'
MAX_FILE_SIZE = 10 * 1024 * 1024  # 跳过 > 10MB 的文件
MAX_FILES = 50  # 每次最多处理 50 个文件


def get_call_cost(model, input_tok, output_tok):
    m = model.lower()
    if 'opus-4' in m:
        return input_tok / 1_000_000 * 15 + output_tok / 1_000_000 * 75, False
    if 'sonnet-4' in m:
        return input_tok / 1_000_000 * 3 + output_tok / 1_000_000 * 15, False
    if 'haiku-4' in m:
        return input_tok / 1_000_000 * 0.8 + output_tok / 1_000_000 * 4, False
    if 'gpt-4o-mini' in m:
        return input_tok / 1_000_000 * 0.15 + output_tok / 1_000_000 * 0.6, False
    if 'gpt-4o' in m:
        return input_tok / 1_000_000 * 2.5 + output_tok / 1_000_000 * 10, False
    if 'qwen3.5-plus' in m:
        return input_tok / 1_000_000 * 0.2 + output_tok / 1_000_000 * 0.6, False
    if 'qwen3-coder-plus' in m:
        return input_tok / 1_000_000 * 0.4 + output_tok / 1_000_000 * 1.2, False
    if 'qwen3-coder-next' in m:
        return input_tok / 1_000_000 * 0.8 + output_tok / 1_000_000 * 2.0, False
    if 'glm' in m or 'minimax' in m or 'qwen' in m or 'kimi' in m:
        return 0.0, True
    return -1.0, False


def load_store():
    if not STORE_FILE.exists():
        return {
            'sessions': {},
            'globalTotal': {'totalCalls': 0, 'totalTokens': 0, 'totalCost': 0.0},
            'trackedFiles': {},
            'lastRun': 0
        }
    with open(STORE_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)


def save_store(store):
    STORE_DIR.mkdir(parents=True, exist_ok=True)
    with open(STORE_FILE, 'w', encoding='utf-8') as f:
        json.dump(store, f, indent=2, ensure_ascii=False)
        f.write('\n')


def scan_file(filepath, tracked_count):
    """返回 (new_calls_list, total_lines_in_file)"""
    stat = filepath.stat()
    if stat.st_size > MAX_FILE_SIZE:
        return [], stat.st_size  # 跳过但标记已读完

    try:
        with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
            lines = f.readlines()
    except Exception:
        return [], 0

    if tracked_count >= len(lines):
        return [], len(lines)

    new_calls = []
    for line in lines[tracked_count:]:
        if not line.strip():
            continue
        try:
            entry = json.loads(line.strip())
        except json.JSONDecodeError:
            continue

        if entry.get('type') != 'message':
            continue
        msg = entry.get('message', {})
        if msg.get('role') != 'assistant':
            continue

        usage = msg.get('usage')
        if not usage:
            continue

        input_tok = usage.get('input') or 0
        output_tok = usage.get('output') or 0
        total_tok = usage.get('totalTokens') or 0

        if not input_tok and not output_tok:
            continue

        eff_tokens = total_tok if total_tok else (input_tok + output_tok)
        provider = msg.get('provider', 'unknown')
        model = msg.get('model', 'unknown')
        cost, is_free = get_call_cost(model, input_tok, output_tok)

        new_calls.append({
            'timestamp': entry.get('timestamp', 0),
            'provider': provider,
            'model': model,
            'inputTokens': input_tok,
            'outputTokens': output_tok,
            'totalTokens': eff_tokens,
            'cost': cost,
            'isFree': is_free,
        })

    return new_calls, len(lines)


def main():
    print("[CostTracker] Starting scan...")
    store = load_store()
    tracked = store.get('trackedFiles', {})
    sessions = store.get('sessions', {})
    global_total = store.get('globalTotal', {'totalCalls': 0, 'totalTokens': 0, 'totalCost': 0.0})

    new_calls_total = 0
    new_tokens_total = 0
    new_cost_total = 0.0
    files_updated = 0

    if not SESSIONS_DIR.exists():
        print(f"[CostTracker] Sessions dir not found: {SESSIONS_DIR}")
        return

    # 只处理最近修改的 N 个文件
    all_files = sorted(SESSIONS_DIR.glob('*.jsonl'), key=lambda p: p.stat().st_mtime, reverse=True)
    files_to_scan = all_files[:MAX_FILES]

    for i, sf in enumerate(files_to_scan):
        fpath = str(sf)
        tracked_count = tracked.get(fpath, 0)
        new_calls, total_lines = scan_file(sf, tracked_count)

        if not new_calls:
            continue

        session_key = sf.stem
        if session_key not in sessions:
            sessions[session_key] = {
                'sessionKey': session_key,
                'totalCalls': 0,
                'totalTokens': 0,
                'totalCost': 0.0,
                'isFree': True,
                'calls': []
            }

        s = sessions[session_key]
        for call in new_calls:
            s['totalCalls'] += 1
            s['totalTokens'] += call['totalTokens']
            s['totalCost'] += call['cost']
            s['isFree'] = s['isFree'] and call['isFree']
            global_total['totalCalls'] += 1
            global_total['totalTokens'] += call['totalTokens']
            global_total['totalCost'] += call['cost']
            new_calls_total += 1
            new_tokens_total += call['totalTokens']
            new_cost_total += call['cost']

            if len(s['calls']) < 50:
                s['calls'].append({
                    'timestamp': call['timestamp'],
                    'model': call['model'],
                    'provider': call['provider'],
                    'inputTokens': call['inputTokens'],
                    'outputTokens': call['outputTokens'],
                    'totalTokens': call['totalTokens'],
                    'cost': call['cost'],
                    'isFree': call['isFree'],
                })

        tracked[fpath] = total_lines
        files_updated += 1

    store['sessions'] = sessions
    store['globalTotal'] = global_total
    store['trackedFiles'] = tracked

    if new_calls_total > 0:
        save_store(store)
        print(f"[CostTracker] Scanned {len(files_to_scan)}/{len(all_files)} session files")
        print(f"[CostTracker] New: {new_calls_total} calls, {new_tokens_total:,} tokens, ${new_cost_total:.6f}")
        print(f"[CostTracker] Files updated: {files_updated}")
        print(f"[CostTracker] Global total: {global_total['totalCalls']} calls, ${global_total['totalCost']:.6f}")
    else:
        print(f"[CostTracker] No new records ({len(files_to_scan)} files scanned)")


if __name__ == '__main__':
    main()
