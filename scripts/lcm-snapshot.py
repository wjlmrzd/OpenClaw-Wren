"""
lossless-claw SQLite DB 预-compaction 快照脚本

原理: 在 lossless-claw compact() 之前备份 SQLite DB。
如果 compact 后发现问题，可以回滚到上一个快照。

用法:
  python lcm-snapshot.py --action backup   # 创建快照
  python lcm-snapshot.py --action list     # 列出可用快照
  python lcm-snapshot.py --action restore  # 回滚到上一个快照
  python lcm-snapshot.py --action prune    # 清理旧快照（保留最近 3 个）
"""

import argparse
import json
import shutil
import sqlite3
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

# 默认路径（可以从环境变量覆盖）
DEFAULT_DB_PATH = Path.home() / ".openclaw" / "lcm.db"
SNAPSHOT_DIR = Path.home() / ".openclaw" / "lcm-snapshots"
MAX_KEEP = 3


def get_db_path() -> Path:
    """从 openclaw.json 读取实际的 DB 路径。"""
    config_path = Path.home() / ".openclaw" / "openclaw.json"
    if config_path.exists():
        try:
            raw = config_path.read_text(encoding="utf-8")
            # 找 plugins.entries."lossless-claw" 或默认 lcm.db
            import re
            m = re.search(r'"dbPath"\s*:\s*"([^"]+)"', raw)
            if m:
                p = Path(m.group(1))
                if p.exists():
                    return p
        except Exception:
            pass
    return DEFAULT_DB_PATH


def backup_db(db_path: Path) -> Optional[Path]:
    """创建 SQLite DB 的热备份（不需要锁 DB）。"""
    if not db_path.exists():
        print(f"DB not found: {db_path}", file=sys.stderr)
        return None

    SNAPSHOT_DIR.mkdir(parents=True, exist_ok=True)

    # 表计数（验证 DB 可读）
    try:
        conn = sqlite3.connect(str(db_path))
        cur = conn.cursor()
        cur.execute("SELECT COUNT(*) FROM sqlite_master WHERE type='table'")
        table_count = cur.fetchone()[0]
        conn.close()
    except Exception as e:
        print(f"Cannot read DB: {e}", file=sys.stderr)
        return None

    ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S")
    backup_name = f"lcm_precompact_{ts}.db"
    backup_path = SNAPSHOT_DIR / backup_name

    try:
        # SQLite 在线备份（不阻塞读写）
        src = sqlite3.connect(str(db_path), timeout=10)
        dst = sqlite3.connect(str(backup_path))
        src.backup(dst)
        src.close()
        dst.close()

        # 验证备份完整性
        verify_conn = sqlite3.connect(str(backup_path))
        verify_cur = verify_conn.cursor()
        verify_cur.execute("SELECT COUNT(*) FROM sqlite_master WHERE type='table'")
        verify_tables = verify_cur.fetchone()[0]
        verify_conn.close()

        if verify_tables != table_count:
            print(f"Backup verification failed: expected {table_count} tables, got {verify_tables}")
            backup_path.unlink(missing_ok=True)
            return None

        # 记录元数据
        meta_path = SNAPSHOT_DIR / f"lcm_precompact_{ts}.meta.json"
        meta = {
            "created_at": datetime.now(timezone.utc).isoformat(),
            "source_db": str(db_path),
            "table_count": table_count,
            "db_size_bytes": db_path.stat().st_size,
            "backup_path": str(backup_path),
        }
        meta_path.write_text(json.dumps(meta, indent=2, ensure_ascii=False), encoding="utf-8")

        print(f"Backup created: {backup_path.name} ({db_path.stat().st_size:,} bytes, {table_count} tables)")
        return backup_path

    except Exception as e:
        print(f"Backup failed: {e}", file=sys.stderr)
        return None


def list_snapshots() -> list[dict]:
    """列出所有可用快照。"""
    if not SNAPSHOT_DIR.exists():
        return []
    snapshots = []
    for meta_file in sorted(SNAPSHOT_DIR.glob("*.meta.json"), reverse=True):
        try:
            meta = json.loads(meta_file.read_text(encoding="utf-8"))
            db_file = meta_file.with_suffix(".db")
            meta["db_exists"] = db_file.exists()
            meta["db_size_bytes"] = db_file.stat().st_size if db_file.exists() else 0
            snapshots.append(meta)
        except Exception:
            pass
    return snapshots


def prune_snapshots(keep: int = MAX_KEEP):
    """清理旧快照，只保留最近的 N 个。"""
    snapshots = list_snapshots()
    to_delete = snapshots[keep:]
    for snap in to_delete:
        db_path = Path(snap["backup_path"])
        meta_path = SNAPSHOT_DIR / f"{db_path.stem}.meta.json"
        if db_path.exists():
            db_path.unlink()
        if meta_path.exists():
            meta_path.unlink()
        print(f"Pruned: {db_path.name}")
    print(f"Kept {min(keep, len(snapshots))} snapshots")


def restore_latest():
    """回滚 DB 到上一个快照（不推荐用于生产，仅紧急恢复）。"""
    snapshots = list_snapshots()
    if not snapshots:
        print("No snapshots available to restore")
        return False

    latest = snapshots[0]
    db_path = get_db_path()
    backup_db_path = Path(latest["backup_path"])

    if not backup_db_path.exists():
        print(f"Backup file not found: {backup_db_path}")
        return False

    print(f"⚠️  RESTORE PLAN:")
    print(f"  Source: {backup_db_path}")
    print(f"  Target: {db_path}")
    print(f"  WARNING: This will overwrite the current DB!")
    print()
    confirm = input("Type 'yes' to confirm: ")
    if confirm.strip() != "yes":
        print("Cancelled.")
        return False

    # 先备份当前 DB
    ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S")
    current_backup = db_path.parent / f"lcm_pre_restore_{ts}.db"
    shutil.copy2(db_path, current_backup)
    print(f"Current DB backed up to: {current_backup}")

    # 恢复
    shutil.copy2(backup_db_path, db_path)
    print(f"Restored: {db_path}")
    return True


def main():
    parser = argparse.ArgumentParser(description="lossless-claw SQLite snapshot manager")
    parser.add_argument("--action", choices=["backup", "list", "restore", "prune"],
                        default="backup", help="Action to perform")
    parser.add_argument("--keep", type=int, default=MAX_KEEP,
                        help=f"Number of snapshots to keep (default: {MAX_KEEP})")
    parser.add_argument("--db-path", type=Path,
                        help="Override DB path")
    args = parser.parse_args()

    db_path = args.db_path or get_db_path()

    if args.action == "backup":
        result = backup_db(db_path)
        if result:
            prune_snapshots(args.keep)
            print("Done.")
        sys.exit(0 if result else 1)

    elif args.action == "list":
        snapshots = list_snapshots()
        if not snapshots:
            print("No snapshots found.")
            return
        print(f"Available snapshots ({len(snapshots)}):")
        for i, s in enumerate(snapshots):
            age = datetime.now(timezone.utc) - datetime.fromisoformat(s["created_at"])
            age_str = f"{age.total_seconds()/3600:.1f}h ago"
            db_exists = "✅" if s["db_exists"] else "❌"
            print(f"  [{i}] {Path(s['backup_path']).name} — {age_str} — "
                  f"{s['db_size_bytes']/1024:.0f}KB — {db_exists} — "
                  f"{s['table_count']} tables")

    elif args.action == "restore":
        success = restore_latest()
        sys.exit(0 if success else 1)

    elif args.action == "prune":
        prune_snapshots(args.keep)
        print("Done.")


if __name__ == "__main__":
    main()
