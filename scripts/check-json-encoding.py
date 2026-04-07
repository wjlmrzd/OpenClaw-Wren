#!/usr/bin/env python3
"""Scan and fix JSON encoding issues in workspace files."""
import os
import sys
import json
import glob

workspace = r"D:\OpenClaw\.openclaw\workspace"
results = []
unparseable = []
has_bom = []
fixed = []

for path in glob.glob(os.path.join(workspace, "**", "*.json"), recursive=True):
    if "node_modules" in path or ".git" in path:
        continue
    try:
        with open(path, "rb") as f:
            raw = f.read()

        bom_present = raw.startswith(b'\xef\xbb\xbf')
        hex_header = " ".join(f"{b:02X}" for b in raw[:6])

        # Decode properly
        if bom_present:
            content = raw[3:].decode("utf-8-sig")
        elif raw.startswith(b'\xff\xfe'):
            content = raw.decode("utf-16-le")
            unparseable.append((path, "UTF-16 LE detected", hex_header))
            continue
        else:
            try:
                content = raw.decode("utf-8")
            except UnicodeDecodeError:
                content = raw.decode("gbk", errors="replace")

        # Try parse
        try:
            json.loads(content)
            parse_ok = True
        except Exception:
            parse_ok = False
            unparseable.append((path, "Parse failed", hex_header))

        rel = path.replace(workspace, "~").replace("\\", "/")
        results.append(f"  {'[BOM]' if bom_present else '     '} | {'OK' if parse_ok else 'FAIL'} | {hex_header:20s} | {rel}")

        if bom_present and parse_ok:
            has_bom.append(path)

    except Exception as e:
        rel = path.replace(workspace, "~").replace("\\", "/")
        results.append(f"  ERROR | {str(e)[:60]:60s} | {rel}")
        unparseable.append((path, str(e), ""))

# Fix BOM files
for path in has_bom:
    try:
        with open(path, "rb") as f:
            raw = f.read()
        clean = raw[3:] if raw.startswith(b'\xef\xbb\xbf') else raw
        with open(path, "wb") as f:
            f.write(clean)
        rel = path.replace(workspace, "~").replace("\\", "/")
        fixed.append(rel)
    except Exception as e:
        pass

# Print report
print("=== JSON Encoding Report ===")
print(f"Total scanned: {len(results)} files")
print(f"Has UTF-8 BOM: {len(has_bom)} files")
print(f"Unparseable: {len(unparseable)} files")
print()
print("--- Files with BOM ---")
for r in results:
    if "[BOM]" in r:
        print(r)
print()
print("--- Unparseable Files ---")
for path, reason, _ in unparseable:
    rel = path.replace(workspace, "~").replace("\\", "/")
    print(f"  {rel}")
    print(f"    Reason: {reason}")
print()
print("--- Fixed (BOM removed) ---")
if fixed:
    for f in fixed:
        print(f"  {f}")
else:
    print("  (none)")

# Write report
report_path = os.path.join(workspace, "scripts", "json-encoding-report.txt")
with open(report_path, "w", encoding="utf-8") as f:
    f.write("=== JSON Encoding Report ===\n")
    f.write(f"Total: {len(results)} | BOM: {len(has_bom)} | Unparseable: {len(unparseable)}\n\n")
    f.write("--- BOM Files ---\n")
    for r in results:
        if "[BOM]" in r:
            f.write(r + "\n")
    f.write("\n--- Unparseable ---\n")
    for path, reason, _ in unparseable:
        rel = path.replace(workspace, "~").replace("\\", "/")
        f.write(f"  {rel}\n    Reason: {reason}\n")
    f.write("\n--- Fixed ---\n")
    for x in fixed:
        f.write(f"  {x}\n")

print(f"\nReport: {report_path}")
