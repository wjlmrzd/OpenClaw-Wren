#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

base_dir = r'D:\OpenClaw\.openclaw\workspace\CadAttrBlockConverter'
project_dir = None

for d in os.listdir(base_dir):
    if d.startswith('转') and os.path.isdir(os.path.join(base_dir, d)):
        csproj_path = os.path.join(base_dir, d, d + '.csproj')
        if os.path.exists(csproj_path):
            project_dir = os.path.join(base_dir, d)
            break

if not project_dir:
    print("Project directory not found")
    sys.exit(1)

# Read full BlockSwapper.cs
blockswapper_path = os.path.join(project_dir, 'Core', 'BlockSwapper.cs')
if os.path.exists(blockswapper_path):
    with open(blockswapper_path, 'r', encoding='utf-8-sig') as f:
        content = f.read()
    print("=== BlockSwapper.cs (full content) ===")
    print(content)

# Read PluginEntry.cs
pluginentry_path = os.path.join(project_dir, 'PluginEntry.cs')
if os.path.exists(pluginentry_path):
    with open(pluginentry_path, 'r', encoding='utf-8-sig') as f:
        content = f.read()
    print("\n\n=== PluginEntry.cs (full content) ===")
    print(content)
