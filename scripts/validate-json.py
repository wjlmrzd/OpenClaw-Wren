import json

with open(r'D:\OpenClaw\.openclaw\workspace\cron\jobs.json', 'r', encoding='utf-8-sig') as f:
    data = json.load(f)
    print(f'JSON valid. Jobs: {len(data["jobs"])}')
    
    # 检查所有模型名称
    models = set()
    for j in data['jobs']:
        if 'model' in j.get('payload', {}):
            models.add(j['payload']['model'])
    print(f'Models used: {models}')
    
    # 检查无效字符
    content = f.read()
    if '\ufffd' in content:
        print('WARNING: Found replacement character (U+FFFD) - encoding issue detected')
    else:
        print('No encoding issues detected')
