#!/usr/bin/env python3
"""
关键词监控系统
- 监控多个目标网站
- 关键词匹配过滤
- 相关性评分
- 自动摘要生成
"""

import json
import re
import sys
import hashlib
from datetime import datetime
from pathlib import Path
from typing import Optional

try:
    import requests
except ImportError:
    print("ERROR: requests not installed.")
    sys.exit(1)

try:
    from bs4 import BeautifulSoup
except ImportError:
    print("ERROR: beautifulsoup4 not installed.")
    sys.exit(1)

# ===================== 配置路径 =====================
SCRIPT_DIR = Path(__file__).parent
CONFIG_FILE = SCRIPT_DIR / "keyword-monitor-config.json"
STATE_FILE = SCRIPT_DIR / "keyword-monitor-state.json"
OUTPUT_FILE = SCRIPT_DIR / "keyword-monitor-output.json"


def load_config() -> dict:
    if not CONFIG_FILE.exists():
        print(f"ERROR: Config file not found: {CONFIG_FILE}")
        sys.exit(1)
    with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)


def load_state() -> dict:
    if not STATE_FILE.exists():
        return {"targets": {}}
    with open(STATE_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)


def save_state(state: dict):
    with open(STATE_FILE, 'w', encoding='utf-8') as f:
        json.dump(state, f, ensure_ascii=False, indent=2)


def compute_hash(text: str) -> str:
    return hashlib.md5(text.encode('utf-8')).hexdigest()


def relevance_score(text: str, keywords: list[str]) -> float:
    """计算文本与关键词的相关性分数"""
    if not keywords:
        return 0.5
    text_lower = text.lower()
    score = 0.0
    for kw in keywords:
        count = text_lower.count(kw.lower())
        if count > 0:
            score += min(count * 0.3, 0.5)
    return min(score, 1.0)


def extract_text_from_html(html: str) -> str:
    """从 HTML 中提取纯文本"""
    soup = BeautifulSoup(html, 'html.parser')
    # 移除脚本和样式
    for tag in soup(["script", "style", "nav", "header", "footer"]):
        tag.decompose()
    text = soup.get_text(separator=' ', strip=True)
    # 清理多余空格
    text = re.sub(r'\s+', ' ', text)
    return text


def extract_github_items(html: str, keywords: list[str]) -> list[dict]:
    """从 GitHub 搜索页面提取项目"""
    soup = BeautifulSoup(html, 'html.parser')
    items = []
    repos = soup.select('li.repo-list-item, .repo-item')
    if not repos:
        repos = soup.select('[data-hydro-click]')[:20]

    for repo in repos[:15]:
        title_el = repo.select_one('a[itemprop="name"], .fs-break-word')
        desc_el = repo.select_one('p, .col-12')
        stars_el = repo.select_one('[href$="/stargazers"], .Link--muted')
        link_el = repo.select_one('a[href^="/"]')

        title = title_el.get_text(strip=True) if title_el else ""
        desc = desc_el.get_text(strip=True) if desc_el else ""
        stars = stars_el.get_text(strip=True) if stars_el else ""
        link = "https://github.com" + link_el['href'] if link_el and link_el.get('href') else ""

        if not title:
            continue

        full_text = f"{title} {desc}"
        score = relevance_score(full_text, keywords)

        if score > 0.3:
            items.append({
                "title": title[:100],
                "description": desc[:200],
                "stars": stars,
                "link": link,
                "score": round(score, 2),
                "keywords_matched": [kw for kw in keywords if kw.lower() in full_text.lower()],
            })

    return items


def extract_stackoverflow_items(html: str, keywords: list[str]) -> list[dict]:
    """从 Stack Overflow 页面提取问题"""
    soup = BeautifulSoup(html, 'html.parser')
    items = []
    questions = soup.select('.question-summary, [data-question-id]')

    for q in questions[:15]:
        title_el = q.select_one('.question-hyperlink, .s-post-summary--title')
        votes_el = q.select_one('.vote-count-post, .s-post-summary--vote-count')
        answers_el = q.select_one('.status strong, .s-post-summary--status')
        tags_el = q.select('.post-tag, .s-tag')

        title = title_el.get_text(strip=True) if title_el else ""
        votes = votes_el.get_text(strip=True) if votes_el else "0"
        answers = answers_el.get_text(strip=True) if answers_el else ""
        tags = [t.get_text(strip=True) for t in tags_el[:5]]

        if not title:
            continue

        full_text = f"{title} {' '.join(tags)}"
        score = relevance_score(full_text, keywords)

        if score > 0.3:
            items.append({
                "title": title[:100],
                "votes": votes,
                "answers": answers,
                "tags": tags,
                "score": round(score, 2),
                "keywords_matched": [kw for kw in keywords if kw.lower() in full_text.lower()],
            })

    return items


def extract_generic_items(html: str, keywords: list[str], url: str) -> list[dict]:
    """通用网页提取（标题 + 链接）"""
    text = extract_text_from_html(html)
    soup = BeautifulSoup(html, 'html.parser')
    items = []

    links = soup.select('a[href]')
    for link_el in links[:30]:
        title = link_el.get_text(strip=True)
        href = link_el.get('href', '')
        if not title or len(title) < 10 or len(title) > 150:
            continue
        if any(x in href for x in ['#', 'javascript', 'login', 'register']):
            continue

        full_text = f"{title} {link_el.parent.get_text(strip=True) if link_el.parent else ''}"
        score = relevance_score(full_text, keywords)

        if score > 0.3:
            if href and not href.startswith('http'):
                from urllib.parse import urlparse
                base = f"{urlparse(url).scheme}://{urlparse(url).netloc}"
                href = base + href

            items.append({
                "title": title[:100],
                "link": href,
                "score": round(score, 2),
                "keywords_matched": [kw for kw in keywords if kw.lower() in full_text.lower()],
            })

    return items[:10]


def fetch_target(target: dict, state: dict) -> list[dict]:
    """抓取单个目标网站"""
    name = target.get("name", "Unknown")
    url = target.get("url", "")
    keywords = target.get("keywords", [])
    target_type = target.get("type", "generic")
    min_relevance = target.get("min_relevance", 0.5)
    max_items = target.get("max_items", 5)

    headers = {
        "User-Agent": target.get("browser_user_agent",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Keyword Monitor/1.0"),
        "Accept": "text/html,application/xhtml+xml",
        "Accept-Language": "en-US,en;q=0.9",
    }

    print(f"🔍 监控: {name} ({url})")

    try:
        resp = requests.get(url, headers=headers, timeout=20)
        resp.raise_for_status()
    except Exception as e:
        print(f"   ⚠️ 抓取失败: {e}")
        return []

    # 提取条目
    if target_type == "github":
        items = extract_github_items(resp.text, keywords)
    elif target_type == "stackoverflow":
        items = extract_stackoverflow_items(resp.text, keywords)
    else:
        items = extract_generic_items(resp.text, keywords, url)

    # 按相关性过滤
    filtered = [it for it in items if it["score"] >= min_relevance]

    # 去重（对比 state）
    target_state = state.get("targets", {}).get(name, {})
    seen_hashes = set(target_state.get("seen", []))
    new_items = []

    for it in filtered[:max_items]:
        h = compute_hash(it["title"])
        if h not in seen_hashes:
            new_items.append(it)
        seen_hashes.add(h)

    # 更新 state
    state.setdefault("targets", {})[name] = {
        "seen": list(seen_hashes)[-100:],  # 保留最近 100 条
        "last_check": datetime.now().isoformat(),
    }

    print(f"   提取: {len(items)} 条, 过滤: {len(filtered)} 条, 新增: {len(new_items)} 条")
    return new_items


def format_summary(results: list[dict], config: dict) -> str:
    """生成摘要"""
    if not results:
        return "🔍 关键词监控\n\n本次检查无新发现 🎉"

    date_str = datetime.now().strftime("%Y-%m-%d")
    lines = [f"🔍 关键词监控日报 - {date_str}\n"]

    total_new = sum(len(r.get("new_items", [])) for r in results)
    lines.append(f"共 {total_new} 条新发现\n")

    for r in results:
        items = r.get("new_items", [])
        if not items:
            continue
        lines.append(f"\n🔹 {r['name']} ({len(items)} 条)")
        for i, item in enumerate(items, 1):
            title = item["title"][:70]
            score = item["score"]
            kws = ", ".join(item.get("keywords_matched", []))
            lines.append(f"{i}. {title}")
            if kws:
                lines.append(f"   🔑 {kws} (匹配度: {score})")

    lines.append(f"\n📊 检查时间: {datetime.now().strftime('%H:%M')}")
    return "\n".join(lines)


def main():
    config = load_config()
    state = load_state()

    targets = [t for t in config.get("targets", []) if t.get("enabled", True)]

    if not targets:
        print("No enabled targets found.")
        sys.exit(0)

    all_results = []

    for target in targets:
        new_items = fetch_target(target, state)
        all_results.append({
            "name": target["name"],
            "url": target["url"],
            "type": target.get("type", "generic"),
            "new_items": new_items,
        })

    # 过滤无新条目的结果
    all_results = [r for r in all_results if r.get("new_items")]

    save_state(state)

    output = {
        "timestamp": datetime.now().isoformat(),
        "results": all_results,
    }
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    summary = format_summary(all_results, config)
    print("\n" + "=" * 50)
    print(summary)
    print("=" * 50)
    print(f"\n详细结果已保存: {OUTPUT_FILE}")

    return output


if __name__ == '__main__':
    main()
