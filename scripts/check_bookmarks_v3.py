#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""批量检测 Edge 收藏夹中的网站可用性 - 使用系统代理"""

import json
import asyncio
import aiohttp
from datetime import datetime
from pathlib import Path
import os

# 配置
BOOKMARKS_PATH = Path.home() / "AppData/Local/Microsoft/Edge/User Data/Default/Bookmarks"
OUTPUT_PATH = Path("D:/OpenClaw/.openclaw/workspace/memory/bookmark-health-report.md")
TIMEOUT = aiohttp.ClientTimeout(total=15)
CONCURRENT_LIMIT = 5

# 使用系统代理
PROXY_URL = "http://127.0.0.1:7897"


def extract_urls(node, path=""):
    """递归提取所有 URL"""
    results = []
    node_type = node.get("type")
    
    if node_type == "url":
        results.append({
            "name": node.get("name", ""),
            "url": node.get("url", ""),
            "path": path,
            "visit_count": node.get("visit_count", 0)
        })
    elif node_type == "folder" or "children" in node:
        new_path = f"{path} > {node.get('name', '')}" if path else node.get("name", "")
        for child in node.get("children", []):
            results.extend(extract_urls(child, new_path))
    
    return results


async def check_url(session, bookmark):
    """检测单个 URL"""
    url = bookmark["url"]
    result = {
        **bookmark,
        "status": "Unknown",
        "http_code": None,
        "response_time_ms": None,
        "error": None,
        "checked_at": datetime.now().isoformat()
    }
    
    # 跳过非 HTTP URL
    if not url.startswith(("http://", "https://")):
        result["status"] = "Skipped"
        return result
    
    try:
        start = datetime.now()
        async with session.get(url, allow_redirects=True, ssl=False, timeout=TIMEOUT, proxy=PROXY_URL) as response:
            await response.content.read(1024)
            elapsed = (datetime.now() - start).total_seconds() * 1000
            
            if response.status < 400:
                result["status"] = "OK"
            else:
                result["status"] = "HTTP Error"
            result["http_code"] = response.status
            result["response_time_ms"] = round(elapsed, 2)
    except asyncio.TimeoutError:
        result["status"] = "Timeout"
        result["error"] = "Request timed out"
    except aiohttp.ClientError as e:
        result["status"] = "Failed"
        result["error"] = str(e)[:100]
    except Exception as e:
        result["status"] = "Error"
        result["error"] = str(e)[:100]
    
    return result


async def check_batch(session, bookmarks):
    """批量检测"""
    tasks = [check_url(session, b) for b in bookmarks]
    return await asyncio.gather(*tasks)


def load_bookmarks():
    """加载 Edge 收藏夹"""
    with open(BOOKMARKS_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    all_urls = []
    for root_name, root_node in data.get("roots", {}).items():
        all_urls.extend(extract_urls(root_node, root_name))
    
    return all_urls


def generate_report(results):
    """生成 Markdown 报告"""
    total = len(results)
    ok = len([r for r in results if r["status"] == "OK"])
    failed = len([r for r in results if r["status"] in ["Failed", "HTTP Error", "Timeout", "Error"]])
    skipped = len([r for r in results if r["status"] == "Skipped"])
    
    failed_sites = [r for r in results if r["status"] in ["Failed", "HTTP Error", "Timeout", "Error"]]
    
    report = f"""# Edge 收藏夹健康检测报告

生成时间: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}

> 使用代理: {PROXY_URL}

## 统计概览

| 指标 | 数量 | 占比 |
|------|------|------|
| 总书签数 | {total} | 100% |
| 正常访问 | {ok} | {ok/total*100:.1f}% |
| 访问失败 | {failed} | {failed/total*100:.1f}% |
| 已跳过 | {skipped} | {skipped/total*100:.1f}% |

## 确认失效的网站

| 名称 | URL | 状态 | HTTP 码 | 错误信息 |
|------|-----|------|---------|----------|
"""
    
    for site in failed_sites:
        error = site.get("error", "") or ""
        error = error.replace("|", "\\|")[:40]
        http_code = site.get("http_code") or "-"
        report += f"| {site['name'][:28]} | {site['url'][:45]}... | {site['status']} | {http_code} | {error} |\n"
    
    report += f"""

## 详细结果

<details>
<summary>点击查看所有网站检测结果 ({total} 个)</summary>

| 名称 | URL | 状态 | HTTP 码 | 响应时间 |
|------|-----|------|---------|----------|
"""
    
    for site in results:
        http_code = site.get("http_code") or "-"
        response_time = f"{site.get('response_time_ms')}ms" if site.get("response_time_ms") else "-"
        report += f"| {site['name'][:22]} | {site['url'][:40]}... | {site['status']} | {http_code} | {response_time} |\n"
    
    report += "\n</details>\n"
    
    return report


async def main():
    """主函数"""
    print("正在加载收藏夹...")
    bookmarks = load_bookmarks()
    print(f"共找到 {len(bookmarks)} 个书签")
    print(f"使用代理: {PROXY_URL}")
    
    print(f"\n开始检测全部 {len(bookmarks)} 个书签...")
    
    connector = aiohttp.TCPConnector(limit=CONCURRENT_LIMIT)
    async with aiohttp.ClientSession(connector=connector) as session:
        results = await check_batch(session, bookmarks)
    
    # 生成报告
    report = generate_report(results)
    OUTPUT_PATH.write_text(report, encoding="utf-8")
    print(f"\n报告已保存到: {OUTPUT_PATH}")
    
    # 显示统计
    ok = len([r for r in results if r["status"] == "OK"])
    failed = len([r for r in results if r["status"] in ["Failed", "HTTP Error", "Timeout", "Error"]])
    print(f"\n检测结果: {ok} 个正常, {failed} 个失败")


if __name__ == "__main__":
    asyncio.run(main())
