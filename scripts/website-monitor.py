#!/usr/bin/env python3
"""
网站更新监控脚本
- 抓取配置的网站列表
- 对比上次内容识别更新
- 输出更新摘要供 AI 处理
"""

import json
import os
import sys
from datetime import datetime
from pathlib import Path

# 配置文件路径
SCRIPT_DIR = Path(__file__).parent
CONFIG_FILE = SCRIPT_DIR / "website-monitor-config.json"
STATE_FILE = SCRIPT_DIR / "website-monitor-state.json"

def load_config():
    """加载网站配置"""
    if not CONFIG_FILE.exists():
        # 默认配置
        default_config = {
            "websites": [
                {
                    "name": "CAD 自学网",
                    "url": "https://www.cadzxw.com",
                    "enabled": True,
                    "categories": ["软件更新", "技术教程"]
                }
            ],
            "max_items_per_site": 10,
            "keywords": ["软件", "更新", "技术", "教程", "版本", "发布", "新品"]
        }
        with open(CONFIG_FILE, 'w', encoding='utf-8') as f:
            json.dump(default_config, f, ensure_ascii=False, indent=2)
        return default_config
    
    with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)

def load_state():
    """加载上次抓取状态"""
    if not STATE_FILE.exists():
        return {"websites": {}}
    
    with open(STATE_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_state(state):
    """保存抓取状态"""
    with open(STATE_FILE, 'w', encoding='utf-8') as f:
        json.dump(state, f, ensure_ascii=False, indent=2)

def extract_links_from_html(html_content):
    """从 HTML 中提取链接和标题（简化版）"""
    import re
    
    links = []
    # 匹配 <a href="xxx">标题</a>
    pattern = r'<a\s+(?:[^>]*?\s+)?href=["\']([^"\']+)["\'][^>]*>([^<]+)</a>'
    matches = re.findall(pattern, html_content)
    
    for href, title in matches[:20]:  # 最多取 20 个链接
        # 过滤非文章链接
        if any(skip in href for skip in ['#', 'javascript:', '/login', '/register', '/about']):
            continue
        if len(title.strip()) < 5 or len(title.strip()) > 100:
            continue
            
        links.append({
            "title": title.strip(),
            "url": href if href.startswith('http') else f"https://www.cadzxw.com{href}"
        })
    
    return links

def compare_with_previous(current_links, previous_links, max_age_days=1):
    """对比识别新链接"""
    if not previous_links:
        return current_links[:10]  # 首次运行，返回前 10 个
    
    previous_urls = set(p.get('url', '') for p in previous_links)
    new_links = []
    
    for link in current_links:
        if link.get('url', '') not in previous_urls:
            new_links.append(link)
    
    return new_links[:10]  # 最多返回 10 条更新

def main():
    """主函数"""
    config = load_config()
    state = load_state()
    
    results = {
        "date": datetime.now().strftime("%Y-%m-%d"),
        "websites": []
    }
    
    for site in config.get("websites", []):
        if not site.get("enabled", True):
            continue
        
        site_name = site["name"]
        site_url = site["url"]
        
        print(f"📡 抓取：{site_name} ({site_url})")
        
        # 获取上次抓取的内容
        site_state = state.get("websites", {}).get(site_name, {})
        previous_links = site_state.get("links", [])
        
        # 这里简化处理，实际应该用 web_fetch 抓取
        # 由于 Python 脚本无法直接调用 web_fetch，我们输出信号让 AI 处理
        print(f"  上次抓取：{len(previous_links)} 条")
        print(f"  配置分类：{site.get('categories', [])}")
        
        results["websites"].append({
            "name": site_name,
            "url": site_url,
            "categories": site.get("categories", []),
            "previous_count": len(previous_links),
            "status": "pending_ai_fetch"
        })
    
    # 保存状态
    save_state(state)
    
    # 输出结果供 AI 处理
    print("\n" + "="*50)
    print("AI 处理指令：")
    print("="*50)
    print(f"请对以下网站进行内容抓取和更新对比：")
    for site in results["websites"]:
        print(f"  - {site['name']}: {site['url']}")
        print(f"    关注分类：{site['categories']}")
    print("\n请返回 JSON 格式结果：")
    print(json.dumps(results, ensure_ascii=False, indent=2))
    
    return results

if __name__ == '__main__':
    main()
