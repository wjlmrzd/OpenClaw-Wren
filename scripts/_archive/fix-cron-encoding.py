#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fix garbled UTF-8 chars in cron/jobs.json"""

import json
import re
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

file_path = r"D:\OpenClaw\.openclaw\workspace\cron\jobs.json"

with open(file_path, "r", encoding="utf-8-sig") as f:
    content = f.read()

# Find all garbled patterns
garbled = re.findall(r'[\ufffd]\?[^"]*', content)
print(f"Found {len(garbled)} garbled patterns:")
for g in garbled:
    print(f"  {repr(g)}")

# Known replacements
fixes = [
    ("浠诲姟鍗忚皟锻炼?", "任务协调员"),
    ("日志清理锻炼?", "日志清理员"),
    ("配置审计锻炼?", "配置审计员"),
    ("资源守护锻炼?", "资源守护者"),
    ("灾难恢复锻炼?", "灾难恢复员"),
    ("错误恢复锻炼?", "错误恢复员"),
    ("检?workspace", "检查 workspace"),
    ("执?git commit ?push", "执行 git commit 和 push"),
    ("统本周各模?Token", "统本周各模型 Token"),
    ("检?Gateway", "检查 Gateway"),
    ("生成的?每日综合报告?", "生成简洁的「每日综合报告」"),
    ("你?OpenClaw", "你是 OpenClaw"),
    ("检?今日及明日", "检查今日及明日"),
    ("今日?检?:", "今日检查："),
    ("项目支持?:", "项目支持："),
    ("需求分?:", "需求分析"),
    ("技术规?:", "技术规划"),
    ("测试验收?:", "测试验收"),
    ("进度跟踪?:", "进度跟踪"),
    ("未完成的功能或待修复?:", "未完成的功能或待修复的问题"),
    ("待办清单?:", "待办清单"),
    ("检?git", "检查 git"),
    ("本周完成事项?:", "本周完成事项回顾"),
    ("重要事件?:", "重要事件记录"),
    ("下周计划?:", "下周计划建议"),
    ("执行 Gateway 预测性", "执行 Gateway 预测性"),
    ("工作日晚间提醒?:", "工作日晚间提醒："),
    ("检查今日待办?:", "检查今日待办完成情况"),
    ("检?openclaw", "检查 openclaw"),
    ("生成的变更?", "生成变更差异"),
    ("备份文件?:", "备份文件清单"),
    ("恢复到?:", "恢复到正常"),
    ("统昨日各模?Token", "统昨日各模型 Token"),
    ("统昨日所?Cron", "统昨日所有 Cron"),
    ("统过去 1 小?", "统过去 1 小时"),
    ("每周各模?Token", "每周各模型 Token"),
    ("检?sessions/", "检查 sessions/"),
    ("清理cron", "清理 cron"),
    ("检?磁盘空间使用率", "检查磁盘空间使用率"),
    ("navigate ?", "navigate ?"),
    ("调?1?", "调整 1?"),
    ("?T", "?T"),
    ("?:", ":"),
    ("?,", ","),
    ("?5", "?5"),
    ("?1", "?1"),
    ("?s", "?s"),
    ("?]", "]"),
    ("?\\\\", "\\\\"),
    ("压缩?删除?", "压缩/删除"),
    ("压缩超过 7 天?", "压缩超过 7 天的"),
    ("删除超过 30 天?", "删除超过 30 天的"),
    ("检?磁盘", "检查磁盘"),
    ("建议?取", "建议采取"),
    ("任务执行结果?,", "任务执行结果，"),
    ("执行结果?,", "执行结果，"),
    ("配置变更摘要?,", "配置变更摘要（如有）"),
    ("? ]", "]"),
    ("发送? Telegram", "发送到 Telegram"),
    ("监? powershell", "监控 powershell"),
    ("发送到 Telegram 8542040756", "发送到 Telegram 8542040756"),
]

fixed = content
fix_count = 0
for old, new in fixes:
    if old in fixed:
        fixed = fixed.replace(old, new)
        print(f"FIXED: {old!r} -> {new!r}")
        fix_count += 1

# Fix remaining �? patterns broadly
fixed = re.sub(r'\ufffd\?', '?', fixed)

# Validate JSON
try:
    data = json.loads(fixed)
    print(f"\nJSON validation: OK ({len(data.get('jobs', []))} jobs)")
    
    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Saved {fix_count} fixes to {file_path}")
except json.JSONDecodeError as e:
    print(f"\nJSON validation: FAILED at pos {e.pos}")
    # Show context around error
    lines = fixed.split('\n')
    line_no = fixed[:e.pos].count('\n')
    print(f"Error near line {line_no + 1}:")
    for i in range(max(0, line_no - 2), min(len(lines), line_no + 3)):
        marker = ">>>" if i == line_no else "   "
        print(f"  {marker} {i+1}: {lines[i][:150]}")
