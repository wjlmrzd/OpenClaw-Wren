"""
Brave Search 月度用量追踪器 v2
- 扫描所有 session 文件（按修改时间降序，大幅提速）
- 阈值: 950次 / 月
- 超过阈值时发送 Telegram 提醒
"""

import json
import os
import sys
from datetime import datetime
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
STATE_FILE = SCRIPT_DIR / "brave-search-state.json"
THRESHOLD = 950
TELEGRAM_ID = "8542040756"


def get_current_month():
    now = datetime.now()
    return f"{now.year}-{now.month:02d}"


def load_state():
    if STATE_FILE.exists():
        try:
            with open(STATE_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {"counts": {}, "last_alert_month": None, "last_scan_month": None, "cached_count": 0}


def save_state(state):
    with open(STATE_FILE, "w", encoding="utf-8") as f:
        json.dump(state, f, ensure_ascii=False, indent=2)


def get_openclaw_home():
    home = Path(os.environ.get("OPENCLAW_HOME", "D:\\OpenClaw"))
    if not (home / "agents").exists():
        home = home / ".openclaw"
    return home


def count_websearch_from_sessions():
    """扫描所有 session 文件，统计当月 web_search 调用次数"""
    openclaw_home = get_openclaw_home()
    sessions_dir = openclaw_home / "agents" / "main" / "sessions"
    if not sessions_dir.exists():
        print(f"  [W] sessions dir not found: {sessions_dir}")
        return 0

    current_month = get_current_month()
    jsonl_files = list(sessions_dir.glob("*.jsonl"))
    if not jsonl_files:
        return 0

    # 按修改时间降序排列，优先扫描最新的文件
    jsonl_files.sort(key=lambda f: f.stat().st_mtime, reverse=True)

    print(f"  Scanning {len(jsonl_files)} session files...")

    count = 0
    seen = set()
    scanned = 0

    # 分批处理，每批后输出进度
    batch_size = 200
    for i in range(0, len(jsonl_files), batch_size):
        batch = jsonl_files[i:i + batch_size]
        for fpath in batch:
            try:
                with open(fpath, "r", encoding="utf-8", errors="ignore") as f:
                    for line in f:
                        line = line.strip()
                        if not line or '"web_search"' not in line:
                            continue
                        try:
                            entry = json.loads(line)
                            ts = entry.get("timestamp", "")
                            if entry.get("type") == "message":
                                content = entry.get("message", {}).get("content", [])
                                if isinstance(content, list):
                                    for item in content:
                                        if (isinstance(item, dict)
                                                and item.get("type") == "toolCall"
                                                and item.get("name") == "web_search"):
                                            cid = item.get("id", "")
                                            key = cid or (ts + str(item.get("arguments", "")))
                                            if key and key not in seen and ts.startswith(current_month):
                                                seen.add(key)
                                                count += 1
                        except Exception:
                            continue
            except Exception:
                continue
            scanned += 1

        print(f"  Progress: {min(i + batch_size, len(jsonl_files))}/{len(jsonl_files)} => {count} calls")

    print(f"  Done. Scanned {scanned} files, total web_search: {count}")
    return count


def send_telegram_alert(message):
    try:
        import urllib.request
        import urllib.parse
        token = os.environ.get("TELEGRAM_BOT_TOKEN")
        if not token:
            print("  [W] TELEGRAM_BOT_TOKEN not set")
            return False
        url = f"https://api.telegram.org/bot{token}/sendMessage"
        data = urllib.parse.urlencode({
            "chat_id": TELEGRAM_ID,
            "text": message,
            "parse_mode": "HTML"
        }).encode("utf-8")
        req = urllib.request.Request(url, data=data, method="POST")
        with urllib.request.urlopen(req, timeout=10) as resp:
            return json.loads(resp.read().decode("utf-8")).get("ok", False)
    except Exception as e:
        print(f"  [E] Telegram send failed: {e}")
        return False


def main():
    print("=== Brave Search Monthly Tracker v2 ===")
    print(f"Threshold: {THRESHOLD}/month")
    print()

    current_month = get_current_month()
    now = datetime.now()
    days_in_month = (datetime(now.year, now.month % 12 + 1, 1) -
                     datetime(now.year, now.month, 1)).days
    day_of_month = now.day
    days_left = max(days_in_month - day_of_month + 1, 1)

    # 先加载状态
    state = load_state()

    # 如果当前月已有手动校准值，直接用它（不被自动扫描覆盖）
    prev_cached = state.get("cached_count", 0)
    prev_manual = state.get("manual_calibration", 0)
    prev_count = state.get("counts", {}).get(current_month, 0)

    print(f"[{current_month}] Counting web_search calls...")
    scan_count = count_websearch_from_sessions()

    # 保留最大值（手动校准 > 扫描 > 缓存）
    count = max(scan_count, prev_manual, prev_count, prev_cached)
    print(f"  Scan={scan_count}, Manual={prev_manual}, Prev={prev_count} => Final={count}")

    # 更新状态
    state["counts"][current_month] = count
    state["last_scan_month"] = current_month
    state["cached_count"] = count
    if prev_manual > 0:
        state["manual_calibration"] = prev_manual

    # 清理旧月份
    months = sorted(state["counts"].keys(), reverse=True)
    if len(months) > 2:
        for m in months[2:]:
            del state["counts"][m]
    save_state(state)

    # 计算指标
    pct = count / THRESHOLD * 100
    daily_avg = count / day_of_month if day_of_month > 0 else 0
    projected = int(daily_avg * days_in_month)
    daily_budget = THRESHOLD / days_in_month
    remaining = THRESHOLD - count
    daily_remaining = remaining / days_left if days_left > 0 else 0

    if pct >= 100:
        status = "[OVER]"
    elif pct >= 80:
        status = "[WARN]"
    else:
        status = "[OK]"

    print()
    print(f"  Current: {count}/{THRESHOLD} ({pct:.1f}%) {status}")
    print(f"  Month progress: {day_of_month}/{days_in_month} days")
    print(f"  Remaining: {remaining} calls")
    print(f"  Daily remaining: ~{daily_remaining:.0f} calls/day")
    print(f"  Projected total: {projected} calls")
    print()

    # 发送提醒
    should_alert = False
    if count >= THRESHOLD:
        should_alert = True
        msg = (
            f"Brave Search Monthly Usage Alert\n\n"
            f"Current: {count} / {THRESHOLD} calls - LIMIT REACHED\n"
            f"Month: {current_month}\n"
            f"Projected: {projected} calls\n"
            f"Suggestion: Reduce search frequency or upgrade Brave API quota"
        )
    elif pct >= 80 and state.get("last_alert_month") != current_month:
        should_alert = True
        state["last_alert_month"] = current_month
        save_state(state)
        msg = (
            f"Brave Search Usage Reminder\n\n"
            f"Current: {count}/{THRESHOLD} ({pct:.1f}%)\n"
            f"Month: {current_month} Day {day_of_month}\n"
            f"Daily quota: ~{daily_budget:.0f} calls/day\n"
            f"Current avg: ~{daily_avg:.1f} calls/day\n"
            f"Projected: {projected} calls"
        )
    else:
        print("No alert needed.")

    if should_alert:
        print("Sending Telegram alert...")
        ok = send_telegram_alert(msg)
        print(f"Telegram alert {'sent OK' if ok else 'FAILED'}")
    print()


if __name__ == "__main__":
    main()
