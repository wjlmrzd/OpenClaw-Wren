"""
log-analyzer.py - Auto-Debugger core
从 OpenClaw 日志中提取错误，匹配模式，生成结构化诊断报告
"""

import json
import os
import re
import sys
from pathlib import Path
from datetime import datetime, timedelta

REPO = Path(os.environ.get('OPENCLAW_REPO', r'D:\OpenClaw\.openclaw'))
WORKSPACE = REPO / 'workspace'
LOG_DIR = WORKSPACE / 'memory'
OUTPUT_FILE = LOG_DIR / 'log-analyzer-report.json'

# ===== 错误模式定义 =====
PATTERNS = [
    {
        'id': 'TIMEOUT',
        'severity': 'warning',
        'keywords': ['timeout', 'timed out', 'TIMEOUT', 'TimedOut'],
        'title': 'Timeout 错误',
        'fix': '检查任务耗时，增加 timeoutSeconds；如果是网络问题，验证代理设置'
    },
    {
        'id': 'ECONNREFUSED',
        'severity': 'error',
        'keywords': ['ECONNREFUSED', 'connection refused', 'Connection refused'],
        'title': '连接被拒绝',
        'fix': '目标服务未启动或端口不可达。检查服务状态和防火墙规则'
    },
    {
        'id': 'API_KEY',
        'severity': 'error',
        'keywords': ['No API key', 'api key', 'AUTH', '401', '403', 'Unauthorized'],
        'title': '认证/API Key 错误',
        'fix': '检查 .env 文件中的 API 凭证；确认 auth-profiles.json 是否存在且正确'
    },
    {
        'id': 'RATE_LIMIT',
        'severity': 'warning',
        'keywords': ['rate limit', 'Rate limit', 'rate_limit', '429', 'Too Many Requests'],
        'title': 'API 速率限制',
        'fix': '降低任务频率，或等待限流窗口重置。检查 cron 任务调度是否有碰撞'
    },
    {
        'id': 'JSON_PARSE',
        'severity': 'error',
        'keywords': ['JSONDecodeError', 'JSON parse error', 'Unexpected token', 'SyntaxError'],
        'title': 'JSON 解析错误',
        'fix': '检查日志/配置文件中是否有语法错误；运行 JSON 验证器定位具体文件和行'
    },
    {
        'id': 'CRON_ERROR',
        'severity': 'error',
        'keywords': ['cron: job execution timed out', 'Error: cron:', 'cron job failed'],
        'title': 'Cron 任务执行失败',
        'fix': '查看具体任务的最近执行记录；检查超时设置和脚本路径'
    },
    {
        'id': 'MEMORY_HIGH',
        'severity': 'error',
        'keywords': ['out of memory', 'OOM', 'memory limit', 'fatal error'],
        'title': '内存不足',
        'fix': 'Gateway 内存过高。考虑重启 Gateway；检查是否有内存泄漏的大文件'
    },
    {
        'id': 'GATEWAY_DOWN',
        'severity': 'error',
        'keywords': ['Gateway is unreachable', 'Gateway Unreachable', 'connection refused'],
        'title': 'Gateway 不可达',
        'fix': 'Gateway 进程可能已崩溃。检查 openclaw gateway status，必要时 restart'
    },
    {
        'id': 'PROXY_ERROR',
        'severity': 'warning',
        'keywords': ['proxy', 'Proxy', '407', '407 Proxy Authentication Required'],
        'title': '代理错误',
        'fix': '验证代理设置（HTTPS_PROXY/http_proxy）；检查代理认证是否过期'
    },
    {
        'id': 'PYTHON_NOT_FOUND',
        'severity': 'error',
        'keywords': ['python', "'python'", 'python.exe', 'python3'],
        'title': 'Python 命令未找到',
        'fix': 'Windows 上使用 `py` 而不是 `python`；检查 PATH 环境变量'
    },
    {
        'id': 'FILE_NOT_FOUND',
        'severity': 'error',
        'keywords': ['ENOENT', 'not found', 'No such file', 'cannot find'],
        'title': '文件未找到',
        'fix': '检查文件路径是否正确；OPENCLAW_REPO 或 OPENCLAW_HOME 环境变量是否设置'
    },
    {
        'id': 'ENCODING_ERROR',
        'severity': 'warning',
        'keywords': ['UnicodeDecodeError', 'UnicodeEncodeError', 'gbk', 'utf-8', 'encoding'],
        'title': '编码错误',
        'fix': 'PowerShell 脚本中的中文在 cmd 链中乱码。使用 UTF-8 with BOM 保存脚本'
    },
    {
        'id': 'HTTP_ERROR',
        'severity': 'warning',
        'keywords': ['HTTP Error', '404', '500', '502', '503', '504'],
        'title': 'HTTP 请求错误',
        'fix': '目标 API/服务不可用；检查网络连接和目标服务状态'
    },
]

# ===== 日志来源 =====
LOG_SOURCES = [
    LOG_DIR / 'events.log',
    LOG_DIR / 'auto-healer-log.md',
    LOG_DIR / 'incident-log.md',
    REPO / 'cron' / 'runs' / 'run-log.txt',
]


def read_log_lines(path, max_lines=500):
    """读取日志文件最后 N 行"""
    if not path.exists():
        return []
    try:
        with open(path, 'r', encoding='utf-8', errors='replace') as f:
            lines = f.readlines()
        return lines[-max_lines:]
    except Exception:
        return []


def match_pattern(line, pattern):
    """检查一行是否匹配某个模式"""
    return any(kw.lower() in line.lower() for kw in pattern['keywords'])


def analyze_source(path, max_lines=500):
    """分析单个日志源"""
    lines = read_log_lines(path, max_lines)
    matches = []

    for i, line in enumerate(lines):
        for pattern in PATTERNS:
            if match_pattern(line, pattern):
                # 提取上下文（前2行+后2行）
                ctx_start = max(0, i - 2)
                ctx_end = min(len(lines), i + 3)
                context = ''.join(lines[ctx_start:ctx_end])

                matches.append({
                    'pattern_id': pattern['id'],
                    'severity': pattern['severity'],
                    'title': pattern['title'],
                    'fix': pattern['fix'],
                    'line_num': len(lines) - max_lines + i + 1,
                    'context': context[:500]  # 限制上下文长度
                })
                break  # 每行只匹配一个模式

    return matches


def analyze_all(since_hours=24):
    """分析所有日志源，返回聚合报告"""
    cutoff = datetime.now() - timedelta(hours=since_hours)
    all_matches = {}
    sources_checked = 0

    for source in LOG_SOURCES:
        sources_checked += 1
        matches = analyze_source(source)

        for m in matches:
            key = f"{m['pattern_id']}@{source.name}"
            if key not in all_matches:
                all_matches[key] = {
                    'pattern_id': m['pattern_id'],
                    'severity': m['severity'],
                    'title': m['title'],
                    'fix': m['fix'],
                    'source': source.name,
                    'occurrences': 0,
                    'last_seen': None,
                    'context': m['context']
                }
            all_matches[key]['occurrences'] += 1
            all_matches[key]['last_seen'] = datetime.now().isoformat()

    # 按严重性排序
    severity_order = {'error': 0, 'warning': 1}
    sorted_matches = sorted(
        all_matches.values(),
        key=lambda x: (severity_order.get(x['severity'], 2), -x['occurrences'])
    )

    report = {
        'generated_at': datetime.now().isoformat(),
        'analyzed_hours': since_hours,
        'sources_checked': sources_checked,
        'errors_found': sum(1 for m in sorted_matches if m['severity'] == 'error'),
        'warnings_found': sum(1 for m in sorted_matches if m['severity'] == 'warning'),
        'matches': sorted_matches,
        'summary': generate_summary(sorted_matches)
    }

    return report


def generate_summary(matches):
    """生成可读摘要"""
    if not matches:
        return "✅ 未检测到已知错误模式。系统日志正常。"

    lines = []
    errors = [m for m in matches if m['severity'] == 'error']
    warnings = [m for m in matches if m['severity'] == 'warning']

    if errors:
        lines.append(f"🔴 发现 {len(errors)} 个错误模式:")
        for m in errors[:5]:
            lines.append(f"  • [{m['pattern_id']}] {m['title']} ({m['occurrences']}次)")
        if len(errors) > 5:
            lines.append(f"  • ... 还有 {len(errors)-5} 个")

    if warnings:
        lines.append(f"⚠️  发现 {len(warnings)} 个警告模式:")
        for m in warnings[:5]:
            lines.append(f"  • [{m['pattern_id']}] {m['title']} ({m['occurrences']}次)")

    return '\n'.join(lines)


def main():
    import argparse
    parser = argparse.ArgumentParser(description='OpenClaw Log Analyzer')
    parser.add_argument('--hours', type=int, default=24, help='分析最近多少小时的日志 (默认24)')
    parser.add_argument('--output', default=str(OUTPUT_FILE), help='输出JSON路径')
    parser.add_argument('--summary-only', action='store_true', help='只输出摘要')
    args = parser.parse_args()

    report = analyze_all(since_hours=args.hours)

    # 保存报告
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(args.output, 'w', encoding='utf-8') as f:
        json.dump(report, f, ensure_ascii=False, indent=2)

    if args.summary_only:
        print(report['summary'])
    else:
        print(json.dumps(report, ensure_ascii=False, indent=2))

    print(f"\n[LogAnalyzer] 报告已保存: {args.output}", file=sys.stderr)
    print(f"[LogAnalyzer] {report['errors_found']} errors, {report['warnings_found']} warnings", file=sys.stderr)

    return 0


if __name__ == '__main__':
    # Fix Windows stdout encoding for PowerShell pipe
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.exit(main())
