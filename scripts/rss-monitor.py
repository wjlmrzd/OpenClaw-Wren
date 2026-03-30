#!/usr/bin/env python3
"""
RSS/订阅源监控脚本
- 读取订阅源列表
- 检查更新（基于 ETags/Last-Modified + 缓存去重）
- 关键词过滤 + 摘要生成
- 输出 JSON 供外部处理或直接打印摘要
"""

import json
import os
import sys
import re
import hashlib
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional

try:
    import feedparser
except ImportError:
    print("ERROR: feedparser not installed. Run: pip install feedparser")
    sys.exit(1)

try:
    import requests
except ImportError:
    print("ERROR: requests not installed. Run: pip install requests")
    sys.exit(1)

try:
    from bs4 import BeautifulSoup
except ImportError:
    print("ERROR: beautifulsoup4 not installed. Run: pip install beautifulsoup4")
    sys.exit(1)

# ===================== 路径配置 =====================
SCRIPT_DIR = Path(__file__).parent
CONFIG_FILE = SCRIPT_DIR / "rss-sources.json"
STATE_FILE = SCRIPT_DIR / "rss-monitor-state.json"
OUTPUT_FILE = SCRIPT_DIR / "rss-monitor-output.json"


def load_config() -> dict:
    """加载 RSS 源配置"""
    if not CONFIG_FILE.exists():
        print(f"ERROR: Config file not found: {CONFIG_FILE}")
        sys.exit(1)
    with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)


def load_state() -> dict:
    """加载监控状态（已发送的条目哈希）"""
    if not STATE_FILE.exists():
        return {"items": {}, "last_run": None}
    with open(STATE_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)


def save_state(state: dict):
    """保存监控状态"""
    with open(STATE_FILE, 'w', encoding='utf-8') as f:
        json.dump(state, f, ensure_ascii=False, indent=2)


def compute_hash(entry: dict) -> str:
    """计算条目唯一哈希"""
    key = f"{entry.get('id', entry.get('link', ''))}-{entry.get('title', '')}"
    return hashlib.md5(key.encode('utf-8')).hexdigest()


def fetch_feed(source: dict) -> tuple[list, dict]:
    """
    抓取单个 RSS 源
    Returns: (entries, feed_meta)
    """
    name = source.get("name", "Unknown")
    url = source.get("url", "")
    keywords = source.get("keywords", [])
    max_items = source.get("max_items", 10)
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 RSS Monitor/1.0"
    }

    try:
        resp = requests.get(url, headers=headers, timeout=15)
        resp.raise_for_status()
    except Exception as e:
        print(f"  ⚠️ 抓取失败: {e}")
        return [], {}

    feed = feedparser.parse(resp.text)
    entries = []

    for entry in feed.entries[:max_items * 2]:  # 多抓一些，过滤后取前 max_items
        title = entry.get("title", "")
        link = entry.get("link", "")
        summary = entry.get("summary", "") or entry.get("description", "")
        published = entry.get("published", entry.get("updated", ""))

        # 清理 HTML
        if summary:
            soup = BeautifulSoup(summary, 'html.parser')
            summary_text = soup.get_text(separator=' ', strip=True)
            if len(summary_text) > 200:
                summary_text = summary_text[:200] + "..."
        else:
            summary_text = ""

        # 关键词过滤
        full_text = (title + " " + summary_text).lower()
        matched_kw = [kw for kw in keywords if kw.lower() in full_text]

        if keywords and not matched_kw:
            continue  # 有关键词配置但没匹配，跳过

        entry_data = {
            "title": title,
            "link": link,
            "summary": summary_text[:150],
            "published": published,
            "source": name,
            "keywords": matched_kw,
            "hash": compute_hash(entry),
        }
        entries.append(entry_data)

    return entries[:max_items], {
        "title": feed.feed.get("title", name),
        "link": feed.feed.get("link", url),
        "entries_count": len(feed.entries),
    }


def deduplicate(new_entries: list, state: dict, max_age_hours: int = 24) -> list:
    """
    去重：新条目 hash 不在 state["items"] 中，或条目超过 max_age_hours
    """
    cutoff = datetime.now() - timedelta(hours=max_age_hours)
    result = []

    for entry in new_entries:
        h = entry["hash"]
        # 无记录 → 新条目
        if h not in state["items"]:
            result.append(entry)
        else:
            # 有记录但超过 24h → 重新出现，算更新
            stored_time = state["items"].get(h, {}).get("time", "")
            if stored_time:
                try:
                    t = datetime.fromisoformat(stored_time)
                    if (datetime.now() - t).total_seconds() > max_age_hours * 3600:
                        result.append(entry)
                except Exception:
                    result.append(entry)

    # 更新状态
    for entry in result:
        state["items"][entry["hash"]] = {
            "title": entry["title"],
            "source": entry["source"],
            "time": datetime.now().isoformat(),
        }

    # 清理过期条目（保留最近 7 天）
    cutoff7 = datetime.now() - timedelta(days=7)
    to_del = []
    for h, info in state["items"].items():
        try:
            t = datetime.fromisoformat(info["time"])
            if t < cutoff7:
                to_del.append(h)
        except Exception:
            to_del.append(h)
    for h in to_del:
        del state["items"][h]

    return result


def format_summary(entries: list, config: dict) -> str:
    """生成 Telegram 友好的摘要"""
    if not entries:
        return "📡 RSS 监控\n\n今日无新更新 🎉"

    date_str = datetime.now().strftime("%Y-%m-%d")
    max_len = config.get("summary_length", 80)

    lines = [f"📡 RSS 监控日报 - {date_str}\n"]

    # 按来源分组
    by_source = {}
    for e in entries:
        src = e["source"]
        if src not in by_source:
            by_source[src] = []
        by_source[src].append(e)

    total = 0
    for src, items in by_source.items():
        lines.append(f"\n🔹 {src} ({len(items)} 条)")
        for i, item in enumerate(items[:5], 1):
            total += 1
            title = item["title"][:60]
            summary = item["summary"][:max_len] if item["summary"] else ""
            kws = ", ".join(item["keywords"]) if item["keywords"] else ""

            line = f"{i}. {title}"
            if summary:
                line += f"\n   💬 {summary}"
            if kws:
                line += f"\n   🔑 {kws}"
            lines.append(line)

    lines.append(f"\n📊 共 {total} 条更新 | {datetime.now().strftime('%H:%M')}")
    return "\n".join(lines)


def main():
    config = load_config()
    state = load_state()
    state["last_run"] = datetime.now().isoformat()

    sources = [s for s in config.get("sources", []) if s.get("enabled", True)]

    if not sources:
        print("No enabled RSS sources found in config.")
        sys.exit(0)

    all_entries = []
    results_detail = []

    for source in sources:
        print(f"📡 抓取: {source['name']}")
        entries, meta = fetch_feed(source)

        new_entries = deduplicate(entries, state, max_age_hours=24)
        all_entries.extend(new_entries)

        print(f"   总条目: {len(entries)}, 新条目: {len(new_entries)}")

        results_detail.append({
            "source": source["name"],
            "url": source["url"],
            "total": len(entries),
            "new": len(new_entries),
            "entries": new_entries,
        })

    # 限制总条目
    max_total = config.get("max_total_items", 20)
    all_entries = all_entries[:max_total]

    # 保存原始 JSON 供其他脚本使用
    output = {
        "timestamp": datetime.now().isoformat(),
        "total_new": len(all_entries),
        "entries": all_entries,
        "by_source": results_detail,
    }
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    save_state(state)

    # 打印摘要
    summary = format_summary(all_entries, config)
    print("\n" + "=" * 50)
    print(summary)
    print("=" * 50)
    print(f"\n详细结果已保存: {OUTPUT_FILE}")

    return output


if __name__ == '__main__':
    main()
