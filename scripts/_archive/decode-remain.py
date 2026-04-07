#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import io, sys, json
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r"D:\OpenClaw\.openclaw\workspace\cron\jobs.json", "rb") as f:
    raw = f.read()

# The 5 remaining garbled names (from fix-remaining.py output)
entries = [
    ("姣忔棩鏃╂姤", 3068, "e5a7a3e5bf94e6a3a9e98f83e29582e5a7a4"),
    ("鏅氶棿鎻愰啋", 3959, "e98f85e6b0b6e6a3bfe98ebbe684b0e5958b"),
    ("姣忓懆鎬荤粨", 4826, "e5a7a3e5bf93e68786e98eace88da4e7b2a8"),
    ("閭�欢鐩戞帶", 6506, "e996adee86bbe6aca2e990a9e6889ee5b8b6"),
    ("妯″瀷浣跨敤鎶ュ憡", 8562, "e5a6afe280b3e780b7e6b5a3e8b7a8e695a4e98eb6e383a5e686a1"),
]

for name, pos, hex_bytes in entries:
    print(f"\n{name}")
    print(f"  Pos: {pos}")
    print(f"  Hex: {hex_bytes}")
    ba = bytes.fromhex(hex_bytes)
    # Show each 3-byte chunk as UTF-8
    for i in range(0, len(ba), 3):
        chunk = ba[i:i+3]
        if len(chunk) == 3:
            try:
                char = chunk.decode('utf-8')
                print(f"    [{i}:{i+3}] {chunk.hex()} = U+{ord(char):04X} = '{char}'")
            except:
                print(f"    [{i}:{i+3}] {chunk.hex()} = ???")
        else:
            print(f"    [{i}:{i+len(chunk)}] {chunk.hex()} (partial)")
    
    # Show surrounding context
    print(f"  Context: {raw[pos-5:pos+len(ba)+5].hex()}")
    print(f"  Context chars: {raw[pos-5:pos+len(ba)+5]}")
