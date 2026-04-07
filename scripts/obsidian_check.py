import os
import json

vault = "E:/software/Obsidian/vault"

# 02_Areas 内容
areas = []
for f in os.listdir(os.path.join(vault, "02_Areas")):
    if f.endswith(".md"):
        areas.append(f)

# knowledge 结构
knowledge_dirs = []
knowledge_files = []
for root, dirs, files in os.walk(os.path.join(vault, "knowledge")):
    rel = os.path.relpath(root, os.path.join(vault, "knowledge"))
    if rel != ".":
        knowledge_dirs.append(rel)
    for f in files:
        if f.endswith(".md"):
            knowledge_files.append(os.path.join(rel, f))

result = {
    "areas": areas,
    "knowledge_dirs": sorted(knowledge_dirs),
    "knowledge_files": sorted(knowledge_files)
}

import sys
sys.stdout.reconfigure(encoding='utf-8')
print(json.dumps(result, ensure_ascii=False, indent=2))