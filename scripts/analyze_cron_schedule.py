import json
from datetime import datetime

def analyze_cron_schedules():
    # Load the current jobs.json
    with open('D:/OpenClaw/.openclaw/workspace/cron/jobs.json', 'r', encoding='utf-8-sig') as f:
        current_jobs = json.load(f)

    print('=== ANALYZING CRON TASK SCHEDULING ===')
    print(f'Total tasks: {len(current_jobs["jobs"])}')
    print()

    # Extract enabled jobs with their schedules
    enabled_jobs = [job for job in current_jobs['jobs'] if job['enabled']]
    print(f'Enabled tasks: {len(enabled_jobs)}')
    print()

    # Parse cron schedules and analyze timing
    schedule_analysis = {}
    for job in enabled_jobs:
        expr = job['schedule']['expr']
        name = job.get('name', 'unnamed')
        
        # Parse basic cron format (minute hour dom month dow)
        parts = expr.split()
        if len(parts) == 5:
            minute, hour, dom, month, dow = parts
            
            # Convert hour to actual hour(s) that run
            hours = []
            if hour == '*':
                hours = list(range(24))
            elif '/' in hour:
                # Handle */N format
                interval = int(hour.replace('*/', ''))
                hours = list(range(0, 24, interval))
            elif '-' in hour and '/' in hour:
                # Handle N-M/X format
                range_part, interval_part = hour.split('/')
                start, end = map(int, range_part.split('-'))
                interval = int(interval_part)
                hours = list(range(start, end + 1, interval))
            elif '-' in hour:
                # Handle N-M format
                start, end = map(int, hour.split('-'))
                hours = list(range(start, end + 1))
            elif ',' in hour:
                # Handle comma separated values
                hours = [int(h) for h in hour.split(',')]
            else:
                # Single hour
                hours = [int(hour)]
            
            # Convert minute to actual minute(s) that run
            minutes = []
            if minute == '*':
                minutes = list(range(60))
            elif '/' in minute:
                # Handle */N format
                interval = int(minute.replace('*/', ''))
                minutes = list(range(0, 60, interval))
            elif ',' in minute:
                # Handle comma separated values
                minutes = [int(m) for m in minute.split(',')]
            else:
                # Single minute
                minutes = [int(minute)]
            
            # Record all possible execution times
            for h in hours:
                for m in minutes:
                    time_key = f'{h:02d}:{m:02d}'
                    if time_key not in schedule_analysis:
                        schedule_analysis[time_key] = []
                    schedule_analysis[time_key].append({
                        'name': name,
                        'id': job['id'],
                        'expr': expr,
                        'timeout': job['payload'].get('timeoutSeconds', 0) if 'payload' in job and 'timeoutSeconds' in job['payload'] else 0
                    })

    # Sort times chronologically
    sorted_times = sorted(schedule_analysis.keys())

    print('=== SCHEDULE COLLISION ANALYSIS ===')
    collisions = []
    heavy_tasks = []
    for time_key in sorted_times:
        tasks_at_time = schedule_analysis[time_key]
        if len(tasks_at_time) > 1:
            collision_info = {
                'time': time_key,
                'count': len(tasks_at_time),
                'tasks': tasks_at_time
            }
            collisions.append(collision_info)
            print(f'[COLLISION] AT {time_key}: {len(tasks_at_time)} tasks')
            for task in tasks_at_time:
                timeout = task['timeout']
                category = 'HEAVY' if timeout > 180 else 'LIGHT'
                if timeout > 180:
                    heavy_tasks.append(task)
                print(f'  - {task["name"]} (timeout: {timeout}s, category: {category})')
            print()

    if not collisions:
        print('[OK] NO COLLISIONS DETECTED')

    print()
    print('=== HEAVY TASKS (timeout > 180s) ===')
    for task in heavy_tasks:
        print(f'- {task["name"]}: {task["timeout"]}s timeout at {task["expr"]}')

    print()
    print('=== TIME DISTRIBUTION ===')
    hourly_counts = {}
    for time_key in sorted_times:
        hour = time_key.split(':')[0]
        if hour not in hourly_counts:
            hourly_counts[hour] = 0
        hourly_counts[hour] += 1

    for hour in sorted(hourly_counts.keys()):
        print(f'Hour {hour}:00 - {hourly_counts[hour]} tasks')

    print()
    print('=== TOP HEAVY TASKS ===')
    all_tasks_with_timeout = [(job.get('name', 'unnamed'), 
                              job['payload'].get('timeoutSeconds', 0) if 'payload' in job and 'timeoutSeconds' in job['payload'] else 0,
                              job['schedule']['expr']) 
                             for job in enabled_jobs 
                             if job['payload'].get('timeoutSeconds', 0) > 180]

    all_tasks_with_timeout.sort(key=lambda x: x[1], reverse=True)
    for name, timeout, schedule in all_tasks_with_timeout[:5]:
        print(f'- {name}: {timeout}s ({schedule})')

if __name__ == "__main__":
    analyze_cron_schedules()