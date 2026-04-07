#!/usr/bin/env python3
"""Re-encode JSON files - strip BOM and re-save with clean UTF-8."""
import json, os

workspace = r"D:\OpenClaw\.openclaw\workspace"

files = [
    r"D:\OpenClaw\.openclaw\workspace\memory\cron-jobs.json",
    r"D:\OpenClaw\.openclaw\workspace\memory\cron-list.json",
    r"D:\OpenClaw\.openclaw\workspace\memory\test-git.json",
]

fixed = []
failed = []

for fp in files:
    try:
        # Use utf-8-sig to auto-strip BOM, replace bad chars
        with open(fp, 'r', encoding='utf-8-sig', errors='replace') as f:
            content = f.read()
        
        data = json.loads(content)  # Validate
        print(f"Parse OK: {os.path.basename(fp)} ({len(data)} top keys)")
        
        # Write clean UTF-8 NO BOM, Unix newlines
        with open(fp, 'w', encoding='utf-8', newline='\n') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        rel = fp.replace(workspace, '~').replace('\\', '/')
        fixed.append(rel)
        print(f"  -> Saved clean UTF-8 NO BOM: {rel}")
    except Exception as e:
        rel = fp.replace(workspace, '~').replace('\\', '/')
        failed.append((rel, str(e)))
        print(f"FAILED {rel}: {e}")

print(f"\nFixed: {len(fixed)}")
print(f"Failed: {len(failed)}")
for f, e in failed:
    print(f"  {f}: {e}")
