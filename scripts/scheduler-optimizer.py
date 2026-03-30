#!/usr/bin/env python3
"""
Scheduler Optimizer - 调度优化器 (自动执行版)
分析 Cron 任务执行时间，检测冲突，自动优化调度
"""
import json
import subprocess
import os
import sys
from datetime import datetime

WORKSPACE = "D:/OpenClaw/.openclaw/workspace"
CRON_JOBS_PATH = os.path.join(WORKSPACE, "cron/jobs.json")
STATE_PATH = os.path.join(WORKSPACE, "memory/scheduler-state.json")
MAX_CHANGES_PER_RUN = 3


def parse_cron_expr(expr: str) -> list:
    """Parse cron expression, return list of 'HH:MM' time slots."""
    parts = expr.strip().split()
    if len(parts) < 5:
        return []

    minute_str, hour_str = parts[0], parts[1]

    def parse_field(field: str, max_val: int) -> list:
        if field == '*':
            return list(range(max_val))
        if field.startswith('*/'):
            step = int(field[2:])
            return list(range(0, max_val, step))
        if ',' in field:
            return [int(x) for x in field.split(',')]
        if '-' in field:
            start, end = field.split('-')
            return list(range(int(start), int(end) + 1))
        return [int(field)]

    minutes = parse_field(minute_str, 60)
    hours = parse_field(hour_str, 24)

    result = []
    for h in hours:
        for m in minutes:
            result.append(f"{h:02d}:{m:02d}")
    return result


def load_jobs():
    with open(CRON_JOBS_PATH, 'r', encoding='utf-8-sig') as f:
        data = json.load(f)
    return data.get('jobs', [])


def analyze_and_optimize():
    jobs = load_jobs()
    enabled = [j for j in jobs if j.get('enabled', False)]

    # Build time slot -> tasks map
    time_slots = {}
    for job in enabled:
        expr = job.get('schedule', {}).get('expr', '')
        times = parse_cron_expr(expr)
        timeout = job.get('payload', {}).get('timeoutSeconds', 0)
        is_heavy = timeout > 180
        slot_key = job.get('schedule', {}).get('kind', '') + ':' + job['id']

        for t in times:
            if t not in time_slots:
                time_slots[t] = []
            time_slots[t].append({
                'id': job['id'],
                'name': job.get('name', 'unnamed'),
                'expr': expr,
                'timeout': timeout,
                'is_heavy': is_heavy,
            })

    # Detect risk slots
    high_risk = []
    medium_risk = []

    for slot, tasks in sorted(time_slots.items()):
        count = len(tasks)
        heavy_count = sum(1 for t in tasks if t['is_heavy'])
        if count >= 4:
            high_risk.append(slot)
        elif count >= 3 and heavy_count >= 2:
            high_risk.append(slot)
        elif count >= 3:
            medium_risk.append(slot)

    print(f"[ANALYSIS] HIGH risk: {len(high_risk)}, MEDIUM risk: {len(medium_risk)}")

    # Generate optimization plan
    planned = []
    for slot in (high_risk + medium_risk):
        tasks = time_slots[slot]
        hour = int(slot.split(':')[0])

        def get_first_minute(expr: str) -> int:
            """Get first minute value from cron expr (handles */N format)."""
            parts = expr.strip().split()
            m = parts[0]
            if m.startswith('*/'):
                return 0  # e.g. */30 -> first is 0 (but also marks as NOT movable)
            if ',' in m:
                return int(m.split(',')[0])
            if '-' in m:
                return int(m.split('-')[0])
            return int(m)

        def is_movable(expr: str) -> bool:
            """Check if a cron expression can be safely minute-shifted."""
            parts = expr.strip().split()
            m = parts[0]
            # */N patterns run every N minutes from 0 - can't just offset
            if m.startswith('*/'):
                return False
            # * means every minute - not specific enough to offset
            if m == '*':
                return False
            return True

        movable = [t for t in tasks
                   if is_movable(t['expr'])
                   and len(tasks) > 1]
        movable_sorted = sorted(movable, key=lambda x: -x['timeout'])
        to_move = movable_sorted[1:]  # keep heaviest, move others

        offset = 5
        for task in to_move:
            if len(planned) >= MAX_CHANGES_PER_RUN:
                break

            parts = task['expr'].split()
            old_min = get_first_minute(task['expr'])
            new_min = old_min + offset
            if new_min >= 60:
                new_min -= 60
                offset = 1

            new_slot = f"{hour:02d}:{new_min:02d}"
            new_count = len(time_slots.get(new_slot, []))

            if new_count <= 1:
                parts[0] = str(new_min)
                new_expr = ' '.join(parts)
                planned.append({
                    'taskId': task['id'],
                    'taskName': task['name'],
                    'oldExpr': task['expr'],
                    'newExpr': new_expr,
                    'oldSlot': slot,
                    'newSlot': new_slot,
                    'reason': 'reduce_collision',
                })
                print(f"  -> {task['name']}: {slot} -> {new_slot}")

    print(f"[PLAN] {len(planned)} changes planned")

    # Execute optimizations
    applied = []
    failed = []

    for change in planned:
        try:
            ps_cmd = (
                f"& 'C:\\Users\\Administrator\\AppData\\Roaming\\npm\\openclaw.ps1' "
                f"cron edit {change['taskId']} --cron \"{change['newExpr']}\" 2>&1"
            )
            result = subprocess.run(
                ['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass',
                 '-Command', ps_cmd],
                capture_output=True, text=True, timeout=60
            )
            if result.returncode == 0:
                print(f"  OK {change['taskName']}: {change['oldSlot']} -> {change['newSlot']}")
                change['status'] = 'success'
                change['appliedAt'] = datetime.now().strftime('%Y-%m-%dT%H:%M:%S+08:00')
                applied.append(change)
            else:
                print(f"  FAIL {change['taskName']}: {result.stderr}")
                failed.append(change)
        except Exception as e:
            print(f"  ERROR {change['taskName']}: {e}")
            failed.append(change)

    # Update state file
    existing_state = {}
    if os.path.exists(STATE_PATH):
        try:
            with open(STATE_PATH, 'r', encoding='utf-8-sig') as f:
                existing_state = json.load(f)
        except Exception:
            pass

    history = existing_state.get('optimizationHistory', [])
    if applied:
        details = ', '.join(f"{c['taskName']} {c['oldSlot']}->{c['newSlot']}" for c in applied)
        history.append({
            'date': datetime.now().strftime('%Y-%m-%dT%H:%M:%S+08:00'),
            'action': 'auto_staggered_scheduling',
            'details': f"Adjusted {len(applied)} tasks: {details}"
        })

    new_state = {
        'lastAnalysisAt': datetime.now().strftime('%Y-%m-%dT%H:%M:%S+08:00'),
        'analysisCycle': existing_state.get('analysisCycle', 0) + 1,
        'totalTasks': len(jobs),
        'highRiskSlots': len(high_risk),
        'mediumRiskSlots': len(medium_risk),
        'plannedChanges': len(planned),
        'appliedChanges': len(applied),
        'failedChanges': len(failed),
        'optimizationHistory': history,
        'riskLevel': 'HIGH' if high_risk else ('MEDIUM' if medium_risk else 'LOW'),
        'recommendation': (
            f"CRITICAL: {len(high_risk)} HIGH-risk slots"
            if high_risk else
            f"WARN: {len(medium_risk)} MEDIUM-risk slots"
            if medium_risk else
            "OK: No collision risks"
        )
    }

    with open(STATE_PATH, 'w', encoding='utf-8') as f:
        json.dump(new_state, f, indent=2, ensure_ascii=False)

    print(f"\n[SUMMARY]")
    print(f"  HIGH risk: {len(high_risk)}")
    print(f"  MEDIUM risk: {len(medium_risk)}")
    print(f"  Planned: {len(planned)}")
    print(f"  Applied: {len(applied)}")
    print(f"  Failed: {len(failed)}")

    return {
        'highRiskSlots': high_risk,
        'mediumRiskSlots': medium_risk,
        'plannedChanges': planned,
        'appliedChanges': applied,
        'failedChanges': failed,
    }


if __name__ == '__main__':
    result = analyze_and_optimize()
    print("\n[JSON_RESULT]")
    print(json.dumps(result, indent=2, ensure_ascii=False))
