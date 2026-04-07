#!/usr/bin/env python3
import json
from pathlib import Path

JOBS_FILE = Path("D:/OpenClaw/.openclaw/cron/jobs.json")

with open(JOBS_FILE, "r", encoding="utf-8") as f:
    data = json.load(f)

for job in data["jobs"]:
    if "知识管理三元组" in job["name"]:
        print(f"任务: {job['name']}")
        print(f"频率: {job['schedule']['expr']}")
        print(f"模型: {job['payload']['model']}")
        print(f"超时: {job['payload'].get('timeoutSeconds', 'N/A')}秒")
        break