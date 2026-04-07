#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import io, sys, json
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r"D:\OpenClaw\.openclaw\workspace\cron\jobs.json", "rb") as f:
    raw = f.read()

with open(r"D:\OpenClaw\.openclaw\workspace\cron\jobs.json", "r", encoding="utf-8-sig") as f:
    data = json.load(f)

# For each job, find its name in raw and show hex
for j in data["jobs"]:
    name = j["name"]
    try:
        name_bytes = name.encode("utf-8")
    except:
        name_bytes = name.encode("utf-8", errors="replace")
    pos = raw.find(name_bytes)
    if pos < 0:
        # Try to find by searching for the id
        id_bytes = j["id"].encode("utf-8")
        id_pos = raw.find(id_bytes)
        if id_pos >= 0:
            # Show surrounding context
            ctx = raw[id_pos:id_pos+200]
            print(f"\nJob: {name!r} (NOT IN RAW - ID found at {id_pos})")
            print(f"  Context: {ctx}")
        else:
            print(f"\nJob: {name!r} - COMPLETELY NOT IN FILE!")
    else:
        print(f"\nJob: {name!r}")
        print(f"  Pos: {pos}, Hex: {name_bytes.hex()}")
        ctx = raw[pos-10:pos+len(name_bytes)+10]
        print(f"  Raw ctx: {ctx}")
        # Decode each char
        decoded = []
        i = 0
        while i < len(name_bytes):
            if name_bytes[i] >= 0xE0 and i+2 < len(name_bytes):
                chunk = name_bytes[i:i+3]
                try:
                    decoded.append(chunk.decode("utf-8"))
                except:
                    decoded.append(f"[BAD:{chunk.hex()}]")
                i += 3
            else:
                decoded.append(chr(name_bytes[i]))
                i += 1
        print(f"  Decoded: {decoded}")
