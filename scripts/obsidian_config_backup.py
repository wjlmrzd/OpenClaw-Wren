#!/usr/bin/env python3
"""
Obsidian OpenClaw Configuration Snapshot Generator
Generates a restore-ready markdown note in Obsidian vault.
"""

import json
import os
from datetime import datetime

OBSIDIAN_VAULT = r"E:\software\Obsidian\vault"
OUTPUT_NOTE = r"04_Archives\OpenClaw-Config-Snapshot.md"
MEMORY_BACKUP_DIR = r"04_Archives\Memory-Backups"
OPENCLAW_CONFIG = r"D:\OpenClaw\.openclaw\openclaw.json"
CRON_JOBS_FILE = r"D:\OpenClaw\.openclaw\cron\jobs.json"
WORKSPACE_DIR = r"D:\OpenClaw\.openclaw\workspace"
ENV_FILE = r"D:\OpenClaw\.openclaw\.env"
MEMORY_DIR = r"D:\OpenClaw\.openclaw\workspace\memory"


def load_json(path):
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8-sig") as f:
            return json.load(f)
    return None


def get_env_keys(path):
    keys = []
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if "=" in line:
                    key = line.split("=", 1)[0].strip()
                    if key and key.isidentifier():
                        keys.append(key)
    return keys


def get_skills():
    skills_dir = os.path.join(WORKSPACE_DIR, "skills")
    skills = []
    if os.path.isdir(skills_dir):
        for d in os.listdir(skills_dir):
            skill_path = os.path.join(skills_dir, d, "SKILL.md")
            desc = "No description"
            if os.path.exists(skill_path):
                with open(skill_path, "r", encoding="utf-8") as f:
                    for line in f:
                        line = line.strip()
                        if line.lower().startswith("description:"):
                            desc = line.split(":", 1)[1].strip()
                            break
            rel_path = os.path.join("<workspace>", "skills", d).replace("\\", "/")
            mtime = datetime.fromtimestamp(os.path.getmtime(os.path.join(skills_dir, d)))
            skills.append({
                "name": d,
                "path": rel_path,
                "desc": desc,
                "date": mtime.strftime("%Y-%m-%d %H:%M")
            })
    return skills


def get_plugins(config):
    plugins = []
    installs = config.get("plugins", {}).get("installs", {})
    for name, info in installs.items():
        plugins.append({
            "name": name,
            "ver": info.get("version", "-"),
            "src": info.get("source", "-"),
        })
    return plugins


def redact_env_refs(obj):
    """Recursively replace ${...} references with <REDACTED>"""
    if isinstance(obj, str):
        import re
        return re.sub(r'\$\{[^}]+\}', '<REDACTED>', obj)
    elif isinstance(obj, dict):
        return {k: redact_env_refs(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [redact_env_refs(v) for v in obj]
    return obj


def md_row(cells, sep="|"):
    return sep + " " + ((" " + sep + " ").join(cells)) + " " + sep


def md_table(headers, rows):
    lines = []
    lines.append(md_row(headers))
    lines.append(md_row(["---"] * len(headers)))
    for row in rows:
        lines.append(md_row(row))
    return lines


def main():
    now = datetime.now()
    timestamp = now.strftime("%Y-%m-%d %H:%M:%S")
    date_str = now.strftime("%Y-%m-%d")

    config = load_json(OPENCLAW_CONFIG)
    cron_jobs = load_json(CRON_JOBS_FILE)
    env_keys = get_env_keys(ENV_FILE)
    skills = get_skills()
    plugins = get_plugins(config) if config else []
    skills.sort(key=lambda x: x["name"])
    plugins.sort(key=lambda x: x["name"])

    # Parse cron jobs array
    if cron_jobs:
        if "jobs" in cron_jobs:
            cron_arr = cron_jobs["jobs"]
        elif "value" in cron_jobs:
            cron_arr = cron_jobs["value"]
        else:
            cron_arr = []
    else:
        cron_arr = []

    # Parse cron job name/schedule
    def get_schedule(j):
        s = j.get("schedule", {})
        return s.get("expr") or s.get("kind") or "custom"

    def get_name(j):
        return j.get("name") or j.get("id", "")

    # Build markdown
    out = []
    add = out.append

    add(f"# OpenClaw Configuration Snapshot")
    add("")
    add(f"> Auto-generated at {timestamp}")
    add("> **Purpose:** Full restore guide if OpenClaw is reset")
    add("")
    add("---")
    add("")
    add("## Recovery Guide")
    add("")
    add("### Files to Restore")
    add("")
    add(md_row(["File", "Location", "Notes"]))
    add(md_row(["---", "---", "---"]))
    files_to_restore = [
        ["openclaw.json", ".openclaw/", "Main config"],
        [".env", ".openclaw/", "Environment variables (API Keys)"],
        ["cron/jobs.json", ".openclaw/", "Scheduled tasks"],
        ["skills/", "workspace/", "All installed skills"],
        ["workspace/", "AGENTS.md, SOUL.md, USER.md, TOOLS.md, MEMORY.md", "Workspace config"],
        ["plugins-graph-memory/", "workspace/", "Graph memory plugin"],
        ["plugins-lossless-claw-enhanced/", "workspace/", "LCM plugin"],
        ["Memory-Backups/ (in vault)", "04_Archives/Memory-Backups/", "Daily memory logs + MEMORY.md"],
    ]
    for r in files_to_restore:
        add(md_row(r))
    add("")
    add("### Recovery Steps")
    add("")
    add("1. Reinstall openclaw-cn: `npm install -g openclaw-cn`")
    add("2. Restore .env: copy the .env section below to .openclaw/.env")
    add("3. Restore openclaw.json: copy the openclaw.json section below")
    add("4. Restore cron/jobs.json: copy the full cron/jobs.json section below")
    add("5. Restore memory: copy files from `04_Archives/Memory-Backups/` to `workspace/` and `memory/`")
    add("6. Reinstall skills: from ClawdHub or run `openclaw skills install <skill-url>`")
    add("7. Restart Gateway: `openclaw gateway restart`")
    add("")
    add("---")
    add("")
    add("## System Info")
    add("")
    add(md_row(["Item", "Value"]))
    add(md_row(["---", "---"]))
    version = config.get("meta", {}).get("lastTouchedVersion", "-") if config else "-"
    touched = config.get("meta", {}).get("lastTouchedAt", "-") if config else "-"
    add(md_row(["OpenClaw Version", version]))
    add(md_row(["Last Updated", touched]))
    add(md_row(["Node.js", "v25.8.0"]))
    add(md_row(["OS", "Windows_NT 10.0.22631"]))
    add(md_row(["Backup Time", timestamp]))
    add("")
    add("---")
    add("")
    add("## Model Configuration")
    add("")
    add("### Providers")
    add("")
    add(md_row(["Provider", "BaseURL", "API"]))
    add(md_row(["---", "---", "---"]))
    providers = (config.get("models", {}) or {}).get("providers", {}) if config else {}
    for pname, pinfo in providers.items():
        base = pinfo.get("baseUrl", "-") if isinstance(pinfo, dict) else "-"
        api = pinfo.get("api", "-") if isinstance(pinfo, dict) else "-"
        add(md_row([pname, base, api]))
    add("")
    add("### Model Aliases")
    add("")
    add(md_row(["Alias", "Full Model"]))
    add(md_row(["---", "---"]))
    models_cfg = (config.get("agents", {}) or {}).get("defaults", {}).get("models", {}) if config else {}
    for alias, minfo in models_cfg.items():
        if isinstance(minfo, dict):
            aval = minfo.get("alias", "-")
        elif isinstance(minfo, str):
            aval = minfo
        else:
            aval = "-"
        add(md_row([alias, str(aval) if aval else "-"]))
    add("")
    add(md_row(["Item", "Model"]))
    add(md_row(["---", "---"]))
    agent_def = (config.get("agents", {}) or {}).get("defaults", {}) if config else {}
    mdl = agent_def.get("model", {}) or {}
    img_mdl = agent_def.get("imageModel", {}) or {}
    def fmt(v):
        if isinstance(v, list): return ", ".join(str(x) for x in v)
        if isinstance(v, dict): return str(v)[:60]
        return str(v) if v else "-"
    add(md_row(["**Default Primary**", fmt(mdl.get("primary"))]))
    add(md_row(["**Default Fallback**", fmt(mdl.get("fallbacks"))]))
    add(md_row(["**Image Model**", fmt(img_mdl.get("primary"))]))
    add("")
    add("---")
    add("")
    add("## Channels")
    add("")
    add("### Telegram")
    add("")
    tg = (config.get("channels", {}).get("telegram", {}) or {}) if config else {}
    if tg:
        add(md_row(["Item", "Value"]))
        add(md_row(["---", "---"]))
        add(md_row(["Bot Name", str(tg.get("name", "-"))]))
        add(md_row(["DM Policy", str(tg.get("dmPolicy", "-"))]))
        add(md_row(["Group Policy", str(tg.get("groupPolicy", "-"))]))
        add(md_row(["Stream Mode", str(tg.get("streamMode", "-"))]))
        add("")
        groups = tg.get("groups", {}) or {}
        if groups:
            add("#### Group Topics")
            add("")
            add(md_row(["Group ID", "Topic Config"]))
            add(md_row(["---", "---"]))
            for gid, ginfo in groups.items():
                topics = ginfo.get("topics", {}) or {}
                if topics:
                    parts = [f"{k}={v}" for k, v in topics.items()]
                    tstr = ", ".join(parts)
                else:
                    tstr = "default"
                add(md_row([str(gid), tstr]))
            add("")
    add("### Feishu")
    add("")
    fl = (config.get("channels", {}).get("feishu", {}) or {}) if config else {}
    if fl:
        add(md_row(["Item", "Value"]))
        add(md_row(["---", "---"]))
        acct = fl.get("accounts", {}).get("main", {}) or {}
        add(md_row(["Default Account", str(fl.get("defaultAccount", "-"))]))
        add(md_row(["Bot Name", str(acct.get("botName", "-"))]))
        add(md_row(["DM Policy", str(acct.get("dmPolicy", "-"))]))
        add(md_row(["Default User", str(acct.get("defaultUser", "-"))]))
        add("")
    add("---")
    add("")
    add(f"## Installed Skills ({len(skills)})")
    add("")
    add(md_row(["Skill", "Path", "Description"]))
    add(md_row(["---", "---", "---"]))
    for s in skills:
        add(md_row([s["name"], s["path"], s["desc"][:60]]))
    add("")
    add("---")
    add("")
    add(f"## Installed Plugins ({len(plugins)})")
    add("")
    add(md_row(["Plugin", "Version", "Source"]))
    add(md_row(["---", "---", "---"]))
    for p in plugins:
        add(md_row([p["name"], p["ver"], p["src"]]))
    add("")
    add("---")
    add("")
    add(f"## Scheduled Tasks ({len(cron_arr)})")
    add("")
    add(md_row(["Status", "Name", "Schedule", "Session"]))
    add(md_row(["---", "---", "---", "---"]))
    for j in cron_arr:
        st = "DISABLED" if j.get("enabled") is False else "OK"
        nm = get_name(j)
        sc = get_schedule(j)
        se = j.get("sessionTarget", "main")
        add(md_row([st, nm[:40], sc[:30], se]))
    add("")
    add("---")
    add("")
    add("## Workspace Key Files")
    add("")
    add(md_row(["File", "Size", "Modified"]))
    add(md_row(["---", "---", "---"]))
    key_files = ["AGENTS.md", "SOUL.md", "USER.md", "IDENTITY.md", "HEARTBEAT.md", "MEMORY.md", "TOOLS.md"]
    for f in key_files:
        fp = os.path.join(WORKSPACE_DIR, f)
        if os.path.exists(fp):
            sz = os.path.getsize(fp) / 1024
            mt = datetime.fromtimestamp(os.path.getmtime(fp)).strftime("%Y-%m-%d %H:%M")
            add(md_row([f, f"{sz:.1f} KB", mt]))
    add("")
    add("---")
    add("")
    add("## .env Keys (Reference)")
    add("")
    add("> Structure only. Real .env is in .openclaw/.env. Do NOT copy values from here.")
    add("")
    add("```bash")
    for k in env_keys:
        add(f"{k}=<YOUR_VALUE>")
    add("```")
    add("")
    add("---")
    add("")
    add("## openclaw.json (Full)")
    add("")
    if config:
        redacted = redact_env_refs(config)
        add("```json")
        add(json.dumps(redacted, indent=2, ensure_ascii=False))
        add("```")
    else:
        add("// Unable to read openclaw.json")
    add("")
    add("---")
    add("")
    add("## cron/jobs.json (Full)")
    add("")
    add("> Complete scheduled tasks config. Can be used directly for restore.")
    add("")
    if cron_jobs:
        add("```json")
        add(json.dumps(cron_jobs, indent=2, ensure_ascii=False))
        add("```")
    else:
        add("// Unable to read cron/jobs.json")
    add("")
    add("---")
    add("")
    add(f"*Auto-generated by obsidian-config-backup.py at {timestamp}*")

    # Write file
    output_path = os.path.join(OBSIDIAN_VAULT, OUTPUT_NOTE)
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    with open(output_path, "w", encoding="utf-8-sig") as f:
        f.write("\n".join(out))

    size_kb = os.path.getsize(output_path) / 1024
    print(f"OK: Snapshot saved to {output_path} ({size_kb:.1f} KB)")
    print(f"OK: Skills={len(skills)}, Plugins={len(plugins)}, CronJobs={len(cron_arr)}")

    # ---- Memory backup ----
    backup_dir = os.path.join(OBSIDIAN_VAULT, MEMORY_BACKUP_DIR)
    os.makedirs(backup_dir, exist_ok=True)

    memory_files = [
        (os.path.join(WORKSPACE_DIR, "MEMORY.md"), f"MEMORY-{date_str}.md"),
    ]

    # Add recent daily logs from memory/
    if os.path.isdir(MEMORY_DIR):
        for fn in sorted(os.listdir(MEMORY_DIR)):
            if fn.endswith(".md") and fn.startswith("20"):
                memory_files.append(
                    (os.path.join(MEMORY_DIR, fn), fn)
                )

    backed_up = []
    for src, dst in memory_files:
        if os.path.exists(src):
            with open(src, "r", encoding="utf-8-sig") as f:
                content = f.read()
            dst_path = os.path.join(backup_dir, dst)
            with open(dst_path, "w", encoding="utf-8-sig") as f:
                f.write(content)
            sz = os.path.getsize(dst_path) / 1024
            backed_up.append(f"{dst} ({sz:.1f} KB)")

    print(f"OK: Memory backed up: {', '.join(backed_up)}")


if __name__ == "__main__":
    main()
