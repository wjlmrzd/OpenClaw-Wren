#!/usr/bin/env python3
"""Predict monthly API usage based on cron job frequencies"""

import json
from pathlib import Path
from datetime import datetime

JOBS_FILE = Path("D:/OpenClaw/.openclaw/cron/jobs.json")

# API provider mapping
PROVIDERS = {
    "minimax-coding-plan": "MiniMax",
    "dashscope-coding-plan": "Dashscope",
}

def parse_cron_expr(expr: str) -> float:
    """Estimate daily execution count from cron expression"""
    # Simple parsing for common patterns
    parts = expr.split()
    if len(parts) != 5:
        return 1.0  # Default once per day
    
    minute, hour, dom, month, dow = parts
    
    # Every N hours: */N in hour field
    if hour.startswith("*/"):
        n = int(hour[2:])
        return 24 / n
    
    # Every N minutes: */N in minute field
    if minute.startswith("*/"):
        n = int(minute[2:])
        return 24 * 60 / n
    
    # Multiple hours: N,M,O
    if "," in hour:
        return len(hour.split(","))
    
    # Specific hour (once daily)
    if hour.isdigit():
        # Check day of week
        if dow == "*":
            return 1.0  # Daily
        elif dow.isdigit():
            return 1.0 / 7  # Weekly
        elif "-" in dow:  # Range like 1-5
            days = dow.split("-")
            count = int(days[1]) - int(days[0]) + 1
            return count / 7
        elif "," in dow:
            return len(dow.split(",")) / 7
        return 1.0
    
    return 1.0  # Default

def main():
    with open(JOBS_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    # Group by API provider
    api_stats = {}
    task_details = []
    
    for job in data["jobs"]:
        if not job.get("enabled", True):
            continue
        
        model = job["payload"].get("model", "unknown")
        name = job["name"]
        expr = job["schedule"].get("expr", "0 0 * * *")
        
        # Determine provider
        provider = "Unknown"
        for prefix, prov_name in PROVIDERS.items():
            if model.startswith(prefix):
                provider = prov_name
                break
        
        # Estimate daily calls
        daily_calls = parse_cron_expr(expr)
        
        # Track stats
        if provider not in api_stats:
            api_stats[provider] = {"tasks": 0, "daily_calls": 0, "monthly_calls": 0}
        
        api_stats[provider]["tasks"] += 1
        api_stats[provider]["daily_calls"] += daily_calls
        api_stats[provider]["monthly_calls"] += daily_calls * 30
        
        task_details.append({
            "name": name,
            "model": model.split("/")[-1],
            "provider": provider,
            "expr": expr,
            "daily": round(daily_calls, 1),
        })
    
    # Sort by daily calls (high to low)
    task_details.sort(key=lambda x: -x["daily"])
    
    # Print report
    print("=" * 60)
    print("📊 API 使用量预测报告")
    print("=" * 60)
    
    print("\n📋 高频任务 (每日≥2次):")
    print("-" * 60)
    for t in task_details:
        if t["daily"] >= 2:
            print(f"{t['name']:25} | {t['model']:15} | {t['daily']:>5}次/日")
    
    print("\n📋 中频任务 (每日1次):")
    print("-" * 60)
    for t in task_details:
        if t["daily"] == 1:
            print(f"{t['name']:25} | {t['model']:15} | {t['daily']:>5}次/日")
    
    print("\n📋 低频任务 (每周/双周):")
    print("-" * 60)
    for t in task_details:
        if t["daily"] < 1:
            print(f"{t['name']:25} | {t['model']:15} | {t['daily']:>5}次/日")
    
    # Summary
    total_monthly = sum(s["monthly_calls"] for s in api_stats.values())
    
    print("\n" + "=" * 60)
    print("📈 月度 API 调用预测")
    print("=" * 60)
    
    for provider in sorted(api_stats.keys()):
        stats = api_stats[provider]
        pct = stats["monthly_calls"] / total_monthly * 100 if total_monthly > 0 else 0
        print(f"\n{provider}:")
        print(f"  任务数: {stats['tasks']}")
        print(f"  日均调用: {stats['daily_calls']:.1f} 次")
        print(f"  月度调用: {stats['monthly_calls']:.0f} 次")
        print(f"  占比: {pct:.1f}%")
    
    # Ratio
    minimax = api_stats.get("MiniMax", {}).get("monthly_calls", 0)
    dashscope = api_stats.get("Dashscope", {}).get("monthly_calls", 0)
    
    if minimax > 0 and dashscope > 0:
        ratio = minimax / dashscope
        print(f"\n当前比例: MiniMax:Dashscope = {ratio:.1f}:1 ≈ {ratio*5:.0f}:5")
        print(f"目标比例: 5:2 (MiniMax占71.4%, Dashscope占28.6%)")

if __name__ == "__main__":
    main()