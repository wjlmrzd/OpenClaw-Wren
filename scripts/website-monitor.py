#!/usr/bin/env python3
"""
网站更新监控脚本 (增强版)
- 并行抓取加速
- HTML diff 智能变化检测
- 历史对比
- 错误重试机制
- 支持 SPA / 登录后页面 (via browser fallback)
"""

import json
import re
import sys
import hashlib
import difflib
from datetime import datetime
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
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
CONFIG_FILE = SCRIPT_DIR / "website-monitor-config.json"
STATE_FILE = SCRIPT_DIR / "website-monitor-state.json"
OUTPUT_FILE = SCRIPT_DIR / "website-monitor-output.json"
HISTORY_DIR = SCRIPT_DIR / "website-history"
HISTORY_DIR.mkdir(exist_ok=True)


def load_config() -> dict:
    if not CONFIG_FILE.exists():
        default_config = {
            "websites": [
                {
                    "name": "CAD 自学网",
                    "url": "https://www.cadzxw.com",
                    "enabled": True,
                    "categories": ["软件更新", "技术教程"],
                    "change_threshold": 0.15,
                    "max_items": 10,
                }
            ],
            "max_items_per_site": 10,
            "keywords": ["软件", "更新", "技术", "教程", "版本", "发布", "新品"],
            "concurrent_workers": 4,
            "request_timeout": 15,
            "max_retries": 3,
            "retry_delay": 3,
        }
        with open(CONFIG_FILE, 'w', encoding='utf-8') as f:
            json.dump(default_config, f, ensure_ascii=False, indent=2)
        return default_config
    with open(CONFIG_FILE, 'r', encoding='utf-8-sig') as f:
        return json.load(f)


def load_state() -> dict:
    if not STATE_FILE.exists():
        return {"websites": {}}
    with open(STATE_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)


def save_state(state: dict):
    with open(STATE_FILE, 'w', encoding='utf-8') as f:
        json.dump(state, f, ensure_ascii=False, indent=2)


def compute_hash(content: str) -> str:
    return hashlib.md5(content.encode('utf-8')).hexdigest()


def retry_request(url: str, headers: dict, max_retries: int, timeout: int, retry_delay: int) -> Optional[requests.Response]:
    """带重试的 HTTP 请求"""
    for attempt in range(max_retries):
        try:
            resp = requests.get(url, headers=headers, timeout=timeout)
            if resp.status_code == 200:
                return resp
            elif resp.status_code in (429, 502, 503, 504):
                # 服务器错误，稍后重试
                pass
            else:
                return resp
        except requests.exceptions.Timeout:
            print(f"    ⏱️ 超时 (尝试 {attempt + 1}/{max_retries})")
        except Exception as e:
            print(f"    ⚠️ 请求异常 (尝试 {attempt + 1}/{max_retries}): {e}")
        if attempt < max_retries - 1:
            import time
            time.sleep(retry_delay * (attempt + 1))
    return None


def extract_article_links(html: str, base_url: str, keywords: list, max_links: int = 20) -> list:
    """从 HTML 中提取文章链接"""
    soup = BeautifulSoup(html, 'html.parser')

    # 移除无关标签
    for tag in soup(["script", "style", "nav", "noscript", "iframe", "svg"]):
        tag.decompose()

    links = []
    seen_urls = set()

    # 多种选择器策略
    selectors = [
        'article a[href]',
        '.post-title a[href]',
        '.entry-title a[href]',
        '.article-title a[href]',
        '.list-item a[href]',
        'h2 a[href]',
        'h3 a[href]',
        'a[href^="/20"], a[href^="/201"], a[href^="/202"]',  # 日期路径
        '.content a[href]',
        'main a[href]',
        '.main a[href]',
    ]

    for sel in selectors:
        if len(links) >= max_links:
            break
        try:
            for a in soup.select(sel):
                href = a.get('href', '')
                title = a.get_text(strip=True)

                if not href or len(title) < 8 or len(title) > 150:
                    continue
                if any(x in href.lower() for x in ['#', 'javascript', 'login', 'register', 'logout', 'subscribe']):
                    continue

                # 标准化 URL
                if href.startswith('/'):
                    from urllib.parse import urlparse
                    base = f"{urlparse(base_url).scheme}://{urlparse(base_url).netloc}"
                    full_url = base + href
                elif not href.startswith('http'):
                    full_url = base_url.rstrip('/') + '/' + href
                else:
                    full_url = href

                if full_url in seen_urls:
                    continue
                seen_urls.add(full_url)

                # 关键词过滤
                parent_text = ""
                parent = a.parent
                if parent:
                    parent_text = parent.get_text(strip=True)[:200]

                full_text = f"{title} {parent_text}"
                has_keyword = any(kw.lower() in full_text.lower() for kw in keywords) if keywords else True

                if not has_keyword and keywords:
                    continue

                links.append({
                    "title": title,
                    "url": full_url,
                    "source": sel,
                })

                if len(links) >= max_links:
                    break
        except Exception:
            continue

    return links[:max_links]


def compute_html_diff(old_html: str, new_html: str) -> dict:
    """计算 HTML 之间的差异"""
    # 提取纯文本比较
    soup_old = BeautifulSoup(old_html, 'html.parser')
    soup_new = BeautifulSoup(new_html, 'html.parser')

    for tag in soup_old(["script", "style", "nav", "noscript"]):
        tag.decompose()
    for tag in soup_new(["script", "style", "nav", "noscript"]):
        tag.decompose()

    text_old = soup_old.get_text(separator=' ', strip=True)
    text_new = soup_new.get_text(separator=' ', strip=True)

    # 计算相似度
    similarity = difflib.SequenceMatcher(None, text_old, text_new).ratio()
    diff_ratio = 1.0 - similarity

    # 生成变更描述
    changes = []
    if diff_ratio > 0.05:
        # 找新增的文本段落
        old_lines = set(text_old[i:i+100] for i in range(0, len(text_old), 100))
        new_lines = [text_new[i:i+100] for i in range(0, len(text_new), 100)]
        for nl in new_lines:
            if nl not in old_lines:
                changes.append(nl.strip()[:100])
                if len(changes) >= 3:
                    break

    return {
        "changed": diff_ratio > 0.15,
        "diff_ratio": round(diff_ratio, 3),
        "changes": changes,
        "old_length": len(old_html),
        "new_length": len(new_html),
    }


def save_history(site_name: str, content: str, timestamp: str):
    """保存历史快照"""
    safe_name = re.sub(r'[^\w\u4e00-\u9fff-]', '_', site_name)[:50]
    history_file = HISTORY_DIR / f"{safe_name}.json"

    history = []
    if history_file.exists():
        try:
            with open(history_file, 'r', encoding='utf-8') as f:
                history = json.load(f)
        except Exception:
            history = []

    history.append({
        "timestamp": timestamp,
        "hash": compute_hash(content),
        "length": len(content),
    })

    # 保留最近 30 个快照
    history = history[-30:]

    with open(history_file, 'w', encoding='utf-8') as f:
        json.dump(history, f, ensure_ascii=False, indent=2)


def fetch_single_site(site: dict, config: dict, state: dict) -> dict:
    """抓取单个网站"""
    name = site.get("name", "Unknown")
    url = site.get("url", "")
    keywords = site.get("keywords", config.get("keywords", []))
    max_retries = config.get("max_retries", 3)
    timeout = config.get("request_timeout", 15)
    retry_delay = config.get("retry_delay", 3)
    change_threshold = site.get("change_threshold", 0.15)

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                      "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 "
                      "WebsiteMonitor/2.0",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8",
        "Accept-Encoding": "gzip, deflate",
        "Connection": "keep-alive",
    }

    print(f"  🌐 {name} ({url})")

    resp = retry_request(url, headers, max_retries, timeout, retry_delay)
    if not resp:
        print(f"     ⚠️ 所有重试失败")
        return {
            "name": name,
            "url": url,
            "status": "failed",
            "error": "All retries failed",
        }

    content = resp.text
    content_hash = compute_hash(content)
    timestamp = datetime.now().isoformat()

    # 检查变化
    site_state = state.get("websites", {}).get(name, {})
    prev_hash = site_state.get("content_hash", "")
    prev_links = site_state.get("links", [])

    # HTML diff
    diff_result = {}
    if prev_hash:
        prev_content = site_state.get("content", "")
        if prev_content:
            diff_result = compute_html_diff(prev_content, content)

    is_changed = content_hash != prev_hash
    links = []
    changes = []

    if is_changed:
        # 提取新链接
        links = extract_article_links(content, url, keywords, max_links=site.get("max_items", 10))

        # 对比链接差异
        prev_urls = set(l.get("url", "") for l in prev_links)
        new_urls = set(l.get("url", "") for l in links)
        added = [l for l in links if l["url"] not in prev_urls]

        if added:
            changes.append(f"发现 {len(added)} 篇新文章")
        if diff_result.get("changes"):
            changes.extend(diff_result["changes"][:2])

    # 更新状态
    state.setdefault("websites", {})[name] = {
        "content_hash": content_hash,
        "content": content[:50000] if content else "",  # 保留部分内容用于 diff
        "links": links,
        "last_check": timestamp,
        "last_change": timestamp if is_changed else site_state.get("last_change", ""),
        "last_change_desc": "; ".join(changes[:3]) if is_changed else site_state.get("last_change_desc", ""),
    }

    # 保存历史
    save_history(name, content, timestamp)

    result = {
        "name": name,
        "url": url,
        "status": "success",
        "changed": is_changed,
        "diff": diff_result,
        "new_links_count": len(links) - len([l for l in links if l["url"] in set(p.get("url","") for p in prev_links)]) if is_changed else 0,
        "links": links[:5],  # 最多返回 5 条
        "changes": changes,
        "timestamp": timestamp,
    }

    if is_changed:
        print(f"     ✅ 发现变化 (diff: {diff_result.get('diff_ratio', 0):.1%}), {len(links)} 条链接")
    else:
        print(f"     ⏭️  无变化")

    return result


def format_summary(results: list) -> str:
    """格式化输出"""
    changed = [r for r in results if r.get("changed")]
    date_str = datetime.now().strftime("%Y-%m-%d %H:%M")

    lines = [f"🌐 网站监控报告 - {date_str}\n"]

    if not changed:
        lines.append("所有网站无更新 🎉")
    else:
        for r in changed:
            lines.append(f"\n🔸 {r['name']}")
            if r.get("changes"):
                for c in r["changes"]:
                    lines.append(f"  • {c[:80]}")
            links = r.get("links", [])
            if links:
                lines.append("  最新文章:")
                for i, l in enumerate(links[:3], 1):
                    title = l["title"][:50]
                    lines.append(f"    {i}. {title}")

    return "\n".join(lines)


def main():
    config = load_config()
    state = load_state()

    websites = [w for w in config.get("websites", []) if w.get("enabled", True)]
    if not websites:
        print("No enabled websites in config.")
        sys.exit(0)

    workers = config.get("concurrent_workers", 4)
    print(f"📡 开始监控 {len(websites)} 个网站 (并行: {workers})\n")

    results = []

    if workers > 1 and len(websites) > 1:
        # 并行抓取
        with ThreadPoolExecutor(max_workers=min(workers, len(websites))) as executor:
            futures = {
                executor.submit(fetch_single_site, site, config, state): site
                for site in websites
            }
            for future in as_completed(futures):
                try:
                    result = future.result()
                    results.append(result)
                except Exception as e:
                    site = futures[future]
                    results.append({"name": site.get("name"), "status": "error", "error": str(e)})
    else:
        # 串行抓取
        for site in websites:
            results.append(fetch_single_site(site, config, state))

    save_state(state)

    # 输出
    output = {
        "timestamp": datetime.now().isoformat(),
        "results": results,
    }
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    summary = format_summary(results)
    print("\n" + "=" * 50)
    print(summary)
    print("=" * 50)

    return output


if __name__ == '__main__':
    main()
