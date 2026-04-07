"""
batch_edit_executor.py - 协同多文件编辑执行器
解析 manifest，执行原子性批量编辑
"""

import json
import os
import re
import subprocess
import sys
from pathlib import Path
from datetime import datetime

WORKSPACE_ROOT = Path(r'D:\OpenClaw\.openclaw\workspace')
MAX_EDITS = 20
MAX_LINES = 10000
FORBIDDEN_PATTERNS = [r'rm\s+-rf', r'del\s+/[fq]\s', r'format\s+[a-z]:', r'\\\\?']

DANGEROUS_VERIFY = ['rm -rf', 'del /', 'format ', 'dd if=', 'mkfs']


def sanitize_path(path_str):
    """安全化路径：禁止 workspace 外部路径"""
    try:
        p = Path(path_str.strip())
        # 相对路径 → 拼接到 workspace
        if not p.is_absolute():
            p = WORKSPACE_ROOT / p
        # 解析 ../
        p = p.resolve()
        # 检查是否在 workspace 内
        if not str(p).startswith(str(WORKSPACE_ROOT.resolve())):
            return None, f"路径越界: {p} (必须在 {WORKSPACE_ROOT})"
        return p, None
    except Exception as e:
        return None, f"路径错误: {e}"


def is_dangerous_verify(cmd):
    """检查 verify 命令是否危险"""
    return any(d in cmd for d in DANGEROUS_VERIFY)


def parse_manifest(text):
    """解析 manifest 文本，返回操作列表"""
    ops = []
    # 匹配每个操作块：### N. edit/create/delete/verify: ...
    # 支持 3 种格式：### 1. edit: path 和 ### edit: path 和 ## edit: path
    lines = text.strip().split('\n')
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        # 匹配操作行
        m = re.match(r'^(?:###\s*)?(\d+)?\.?\s*(edit|create|delete|verify|verify-only):\s*(.*)', line, re.IGNORECASE)
        if m:
            op_type = m.group(2).lower()
            content = m.group(3).strip() if m.group(3) else ''

            if op_type in ('edit', 'create'):
                file_path = content
                # 提取 old/new
                old_text = ''
                new_text = ''
                j = i + 1
                while j < len(lines):
                    sub = lines[j].strip()
                    if sub.startswith('old:'):
                        old_text = sub[4:].strip()
                    elif sub.startswith('new:'):
                        new_text = sub[4:].strip()
                    elif sub.startswith('```') or re.match(r'^###?\s*\d', sub):
                        break
                    j += 1

                if op_type == 'edit' and not old_text:
                    return None, f"edit 操作缺少 old: {line}"
                if not file_path:
                    return None, f"{op_type} 操作缺少文件路径"

                ops.append({
                    'type': op_type,
                    'file': file_path,
                    'old': old_text,
                    'new': new_text,
                    'lineno': i + 1
                })
                i = j
                continue

            elif op_type == 'delete':
                ops.append({
                    'type': 'delete',
                    'file': content,
                    'lineno': i + 1
                })
                i += 1
                continue

            elif op_type in ('verify', 'verify-only'):
                ops.append({
                    'type': op_type,
                    'command': content,
                    'lineno': i + 1
                })
                i += 1
                continue

        i += 1

    if not ops:
        return None, "未找到任何操作 (edit/create/delete/verify)"
    if len(ops) > MAX_EDITS:
        return None, f"操作数 {len(ops)} 超过限制 ({MAX_EDITS})"

    return ops, None


def dry_run(ops):
    """Dry-run: 验证所有 oldText 匹配"""
    results = []
    for op in ops:
        if op['type'] == 'edit':
            path, err = sanitize_path(op['file'])
            if err:
                results.append({'op': op, 'ok': False, 'error': err})
                continue
            if not path.exists():
                results.append({'op': op, 'ok': False, 'error': f"文件不存在: {path}"})
                continue
            try:
                content = path.read_text(encoding='utf-8', errors='replace')
                if op['old'] not in content:
                    results.append({
                        'op': op,
                        'ok': False,
                        'error': f"oldText 在文件中未找到",
                        'hint': f"文件当前包含 {len(content)} 字符"
                    })
                else:
                    count = content.count(op['old'])
                    results.append({'op': op, 'ok': True, 'count': count})
            except Exception as e:
                results.append({'op': op, 'ok': False, 'error': str(e)})

        elif op['type'] == 'create':
            path, err = sanitize_path(op['file'])
            if err:
                results.append({'op': op, 'ok': False, 'error': err})
            else:
                if path.exists():
                    results.append({'op': op, 'ok': False, 'error': f"文件已存在: {path}"})
                else:
                    results.append({'op': op, 'ok': True})

        elif op['type'] == 'delete':
            path, err = sanitize_path(op['file'])
            if err:
                results.append({'op': op, 'ok': False, 'error': err})
            elif not path.exists():
                results.append({'op': op, 'ok': False, 'error': f"文件不存在: {path}"})
            else:
                results.append({'op': op, 'ok': True})

        elif op['type'] == 'verify':
            if is_dangerous_verify(op['command']):
                results.append({'op': op, 'ok': False, 'error': 'Forbidden dangerous command'})
            else:
                results.append({'op': op, 'ok': True, 'dry_run': True})

        elif op['type'] == 'verify-only':
            if is_dangerous_verify(op['command']):
                results.append({'op': op, 'ok': False, 'error': 'Forbidden dangerous command'})
            else:
                results.append({'op': op, 'ok': True, 'dry_run': True})

    return results


def execute(ops, skip_dry_run=False):
    """执行所有操作，已执行的文件会备份到 .backup/"""
    backup_dir = WORKSPACE_ROOT / '.batch-edit-backup'
    backup_dir.mkdir(exist_ok=True)

    results = []
    applied = []  # 已执行的操作（用于回滚）
    ts = datetime.now().strftime('%Y%m%d_%H%M%S')

    # Dry-run first
    if not skip_dry_run:
        dry_results = dry_run(ops)
        failed = [r for r in dry_results if not r['ok']]
        if failed:
            return {
                'status': 'dry_run_failed',
                'dry_run_results': dry_results,
                'failed_ops': failed,
                'message': f"Dry-run 失败，{len(failed)} 个操作有问题，详见 results"
            }

    # Execute
    for op in ops:
        if op['type'] == 'edit':
            path, err = sanitize_path(op['file'])
            if err:
                results.append({'op': op, 'ok': False, 'error': err})
                rollback(applied)
                return {'status': 'rollback', 'rollback_ops': applied, 'failed': op, 'error': err}

            try:
                content = path.read_text(encoding='utf-8', errors='replace')
                # 行数检查
                if len(content.splitlines()) > MAX_LINES:
                    results.append({'op': op, 'ok': False, 'error': f"文件超过 {MAX_LINES} 行"})
                    rollback(applied)
                    return {'status': 'rollback', 'rollback_ops': applied, 'failed': op}

                # 备份
                backup_path = backup_dir / f"{ts}_{path.name}"
                backup_path.write_text(content, encoding='utf-8')

                new_content = content.replace(op['old'], op['new'], 1)
                path.write_text(new_content, encoding='utf-8')

                results.append({'op': op, 'ok': True, 'backup': str(backup_path)})
                applied.append({'op': op, 'backup_path': backup_path})

            except Exception as e:
                results.append({'op': op, 'ok': False, 'error': str(e)})
                rollback(applied)
                return {'status': 'rollback', 'rollback_ops': applied, 'failed': op, 'error': str(e)}

        elif op['type'] == 'create':
            path, err = sanitize_path(op['file'])
            if err:
                results.append({'op': op, 'ok': False, 'error': err})
                rollback(applied)
                return {'status': 'rollback', 'applied': applied}

            try:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(op['old'], encoding='utf-8')  # old 字段存内容
                results.append({'op': op, 'ok': True})
                applied.append({'op': op})
            except Exception as e:
                results.append({'op': op, 'ok': False, 'error': str(e)})
                rollback(applied)
                return {'status': 'rollback', 'applied': applied}

        elif op['type'] == 'delete':
            path, err = sanitize_path(op['file'])
            if err:
                results.append({'op': op, 'ok': False, 'error': err})
                rollback(applied)
                return {'status': 'rollback', 'applied': applied}

            try:
                # 备份再删
                if path.exists():
                    backup_path = backup_dir / f"{ts}_{path.name}"
                    backup_path.write_text(path.read_text(encoding='utf-8'), encoding='utf-8')
                    path.unlink()
                results.append({'op': op, 'ok': True, 'backup': str(backup_path)})
                applied.append({'op': op, 'backup_path': backup_path})
            except Exception as e:
                results.append({'op': op, 'ok': False, 'error': str(e)})
                rollback(applied)
                return {'status': 'rollback', 'applied': applied}

        elif op['type'] in ('verify', 'verify-only'):
            if is_dangerous_verify(op['command']):
                results.append({'op': op, 'ok': False, 'error': 'Forbidden'})
                rollback(applied)
                return {'status': 'rollback', 'applied': applied}

            try:
                result = subprocess.run(
                    op['command'],
                    shell=True,
                    capture_output=True,
                    timeout=30,
                    cwd=str(WORKSPACE_ROOT),
                    encoding='utf-8',
                    errors='replace'
                )
                matched = result.returncode == 0
                output = result.stdout.strip()[:500]

                if op['type'] == 'verify' and not matched:
                    results.append({
                        'op': op,
                        'ok': False,
                        'error': 'verify 命令未找到匹配项',
                        'output': output,
                        'stderr': result.stderr[:200]
                    })
                    rollback(applied)
                    return {'status': 'verify_failed', 'applied': applied, 'verify_result': results[-1]}
                else:
                    results.append({'op': op, 'ok': True, 'output': output, 'matched': matched})

            except subprocess.TimeoutExpired:
                results.append({'op': op, 'ok': False, 'error': 'verify 命令超时'})
                rollback(applied)
                return {'status': 'verify_failed', 'applied': applied}
            except Exception as e:
                results.append({'op': op, 'ok': False, 'error': str(e)})
                rollback(applied)
                return {'status': 'rollback', 'applied': applied}

    return {'status': 'success', 'results': results, 'backup_dir': str(backup_dir)}


def rollback(applied):
    """回滚已执行的操作"""
    for item in reversed(applied):
        op = item['op']
        if op['type'] == 'edit' and 'backup_path' in item:
            try:
                path, _ = sanitize_path(op['file'])
                if path:
                    path.write_text(item['backup_path'].read_text(encoding='utf-8'), encoding='utf-8')
            except Exception:
                pass
        elif op['type'] == 'create':
            try:
                path, _ = sanitize_path(op['file'])
                if path and path.exists():
                    path.unlink()
            except Exception:
                pass


def format_report(report):
    """格式化输出为可读报告"""
    if report['status'] == 'success':
        edits = [r for r in report['results'] if r['op']['type'] in ('edit', 'create', 'delete')]
        verifies = [r for r in report['results'] if r['op']['type'] in ('verify', 'verify-only')]
        lines = [f"✅ Batch edit 成功 ({len(edits)} 个文件操作)"]
        for r in edits:
            op = r['op']
            lines.append(f"  • {op['type']}: {op.get('file', '')}")
        if verifies:
            lines.append(f"\n验证通过 ({len(verifies)} 个命令)")
        lines.append(f"\n备份目录: {report.get('backup_dir', 'N/A')}")
        return '\n'.join(lines)

    elif report['status'] == 'dry_run_failed':
        lines = [f"⚠️ Dry-run 失败 ({len(report['failed_ops'])} 个问题)"]
        for r in report['failed_ops']:
            op = r['op']
            lines.append(f"  ❌ [{op['type']}] {op.get('file', op.get('command', ''))}")
            lines.append(f"     原因: {r['error']}")
        return '\n'.join(lines)

    elif report['status'] in ('rollback', 'verify_failed'):
        lines = [f"🔄 操作已回滚"]
        if 'failed' in report:
            lines.append(f"失败: {report['failed']['op']['type']} - {report.get('error', '')}")
        return '\n'.join(lines)

    return json.dumps(report, ensure_ascii=False, indent=2)


def main():
    import argparse
    parser = argparse.ArgumentParser(description='Batch Edit Executor')
    parser.add_argument('--manifest', '-m', required=True, help='Manifest 文本或文件路径')
    parser.add_argument('--skip-dry-run', action='store_true', help='跳过 dry-run')
    parser.add_argument('--json', action='store_true', help='JSON 输出')
    parser.add_argument('--manifest-is-file', action='store_true', help='manifest 参数是文件路径')
    args = parser.parse_args()

    if args.manifest_is_file:
        manifest_path = Path(args.manifest)
        if manifest_path.exists():
            manifest_text = manifest_path.read_text(encoding='utf-8', errors='replace')
        else:
            print(f"❌ Manifest 文件不存在: {manifest_path}")
            return 1
    else:
        manifest_text = args.manifest

    ops, err = parse_manifest(manifest_text)
    if err:
        print(f"❌ 解析错误: {err}")
        return 1

    report = execute(ops, skip_dry_run=args.skip_dry_run)

    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(format_report(report))

    return 0 if report['status'] == 'success' else 1


if __name__ == '__main__':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.exit(main())
