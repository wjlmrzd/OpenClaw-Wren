#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""批量检测 Edge 收藏夹中的网站可用性"""

import json
import csv
import asyncio
import aiohttp
from datetime import datetime
from pathlib import Path

# 配置
BOOKMARKS_PATH = Path.home() / "AppData/Local/Microsoft/Edge/User Data/Default/Bookmarks"
OUTPUT_PATH = Path("D:/OpenClaw/.openclaw/workspace/memory/bookmark-health-report.md")
TIMEOUT = aiohttp.ClientTimeout(total=10)
CONCURRENT_LIMIT = 10


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
        async with session.head(url, allow_redirects=True, ssl=False) as response:
            elapsed = (datetime.now() - start).total_seconds() * 1000
            result["status"] = "OK" if response.status < 400 else "HTTP Error"
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
    
    # 按状态分组
    failed_sites = [r for r in results if r["status"] != "OK" and r["status"] != "Skipped"]
    
    report = f"""# Edge 收藏夹健康检测报告

生成时间: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}

## 统计概览

| 指标 | 数量 |
|------|------|
| 总书签数 | {total} |
| 正常访问 | {ok} |
| 访问失败 | {failed} |
| 已跳过 | {skipped} |
| 成功率 | {ok/total*100:.1f}% |

## 失效网站清单

| 名称 | URL | 状态 | 错误信息 |
|------|-----|------|----------|
"""
    
    for site in failed_sites:
        error = site.get("error", "") or ""
        error = error.replace("|", "\\|")[:50]
        report += f"| {site['name'][:30]} | {site['url'][:50]} | {site['status']} | {error} |\n"
    
    report += f"""

## 详细结果

<details>
<summary>点击查看所有网站检测结果</summary>

| 名称 | URL | 状态 | HTTP 码 | 响应时间 |
|------|-----|------|---------|----------|
"""
    
    for site in results:
        http_code = site.get("http_code") or "-"
        response_time = f"{site.get('response_time_ms')}ms" if site.get("response_time_ms") else "-"
        report += f"| {site['name'][:30]} | {site['url'][:40]}... | {site['status']} | {http_code} | {response_time} |\n"
    
    report += "\n</details>\n"
    
    return report


async def main():
    """主函数"""
    print("正在加载收藏夹...")
    bookmarks = load_bookmarks()
    print(f"共找到 {len(bookmarks)} 个书签")
    
    # 检测全部书签
    bookmarks_to_check = bookmarks
    print(f"本次检测全部 {len(bookmarks_to_check)} 个书签...")
    
    connector = aiohttp.TCPConnector(limit=CONCURRENT_LIMIT)
    async with aiohttp.ClientSession(timeout=TIMEOUT, connector=connector) as session:
        results = await check_batch(session, bookmarks_to_check)
    
    # 生成报告
    report = generate_report(results)
    OUTPUT_PATH.write_text(report, encoding="utf-8")
    print(f"\n报告已保存到: {OUTPUT_PATH}")
    
    # 显示统计
    ok = len([r for r in results if r["status"] == "OK"])
    failed = len([r for r in results if r["status"] not in ["OK", "Skipped"]])
    print(f"\n检测结果: {ok} 个正常, {failed} 个失败")


if __name__ == "__main__":
    asyncio.run(main())
