#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""批量检测 Edge 收藏夹中的网站可用性 - 使用 GET 请求"""

import json
import asyncio
import aiohttp
from datetime import datetime
from pathlib import Path

# 配置
BOOKMARKS_PATH = Path.home() / "AppData/Local/Microsoft/Edge/User Data/Default/Bookmarks"
OUTPUT_PATH = Path("D:/OpenClaw/.openclaw/workspace/memory/bookmark-health-report.md")
TIMEOUT = aiohttp.ClientTimeout(total=15)
CONCURRENT_LIMIT = 5  # 降低并发避免被封


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
    """检测单个 URL - 使用 GET 请求"""
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
        # 使用 GET 请求并只读取前 1KB 内容
        async with session.get(url, allow_redirects=True, ssl=False, timeout=TIMEOUT) as response:
            # 只读取部分内容避免大页面
            await response.content.read(1024)
            elapsed = (datetime.now() - start).total_seconds() * 1000
            
            if response.status < 400:
                result["status"] = "OK"
            elif response.status in [403, 405]:
                # 403/405 可能是防护，尝试用 HEAD 确认
                result["status"] = "Protected"
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
    protected = len([r for r in results if r["status"] == "Protected"])
    failed = len([r for r in results if r["status"] in ["Failed", "HTTP Error", "Timeout", "Error"]])
    skipped = len([r for r in results if r["status"] == "Skipped"])
    
    # 按状态分组
    failed_sites = [r for r in results if r["status"] in ["Failed", "HTTP Error", "Timeout", "Error"]]
    protected_sites = [r for r in results if r["status"] == "Protected"]
    
    report = f"""# Edge 收藏夹健康检测报告

生成时间: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}

## 统计概览

| 指标 | 数量 | 说明 |
|------|------|------|
| 总书签数 | {total} | - |
| 正常访问 | {ok} | 可正常打开 |
| 访问受限 | {protected} | 有防护但可能可用 |
| 访问失败 | {failed} | 确认失效 |
| 已跳过 | {skipped} | 非 HTTP 链接 |
| 健康度 | {(ok+protected)/total*100:.1f}% | 正常+受限 |

## 确认失效的网站

| 名称 | URL | 状态 | 错误信息 |
|------|-----|------|----------|
"""
    
    for site in failed_sites:
        error = site.get("error", "") or ""
        error = error.replace("|", "\\|")[:50]
        report += f"| {site['name'][:30]} | {site['url'][:50]} | {site['status']} | {error} |\n"
    
    if protected_sites:
        report += f"""

## 访问受限的网站（可能需要人工确认）

| 名称 | URL | HTTP 码 |
|------|-----|---------|
"""
        for site in protected_sites:
            report += f"| {site['name'][:30]} | {site['url'][:50]} | {site['http_code']} |\n"
    
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
        report += f"| {site['name'][:25]} | {site['url'][:35]}... | {site['status']} | {http_code} | {response_time} |\n"
    
    report += "\n</details>\n"
    
    return report


async def main():
    """主函数"""
    print("正在加载收藏夹...")
    bookmarks = load_bookmarks()
    print(f"共找到 {len(bookmarks)} 个书签")
    
    print(f"开始检测全部 {len(bookmarks)} 个书签...")
    print("使用 GET 请求，超时 15 秒，并发 5 个...")
    
    connector = aiohttp.TCPConnector(limit=CONCURRENT_LIMIT)
    async with aiohttp.ClientSession(connector=connector) as session:
        results = await check_batch(session, bookmarks)
    
    # 生成报告
    report = generate_report(results)
    OUTPUT_PATH.write_text(report, encoding="utf-8")
    print(f"\n报告已保存到: {OUTPUT_PATH}")
    
    # 显示统计
    ok = len([r for r in results if r["status"] == "OK"])
    protected = len([r for r in results if r["status"] == "Protected"])
    failed = len([r for r in results if r["status"] in ["Failed", "HTTP Error", "Timeout", "Error"]])
    print(f"\n检测结果:")
    print(f"  正常: {ok} 个")
    print(f"  受限: {protected} 个")
    print(f"  失败: {failed} 个")


if __name__ == "__main__":
    asyncio.run(main())
