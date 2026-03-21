#!/usr/bin/env python3
"""
邮件检查脚本 - 用于 Cron 任务监控
检查 IMAP 邮箱的未读邮件，输出摘要
"""

import imaplib
import email
from email.header import decode_header
import json
import sys
import os
from datetime import datetime, timedelta

def decode_mime_words(s):
    """解码 MIME 编码的字符串"""
    if not s:
        return ""
    decoded = []
    for part, encoding in decode_header(s):
        if isinstance(part, bytes):
            try:
                decoded.append(part.decode(encoding or 'utf-8', errors='replace'))
            except:
                decoded.append(part.decode('utf-8', errors='replace'))
        else:
            decoded.append(str(part))
    return ''.join(decoded)

def check_email(config):
    """检查邮件并返回摘要"""
    try:
        # 连接 IMAP 服务器
        mail = imaplib.IMAP4_SSL(config['host'], config['port'])
        mail.login(config['email'], config['password'])
        mail.select('INBOX')
        
        # 搜索未读邮件
        status, messages = mail.search(None, 'UNSEEN')
        email_ids = messages[0].split()
        
        if not email_ids:
            return {
                'status': 'ok',
                'unread_count': 0,
                'emails': [],
                'message': '没有未读邮件'
            }
        
        # 获取最近的 10 封未读邮件
        emails_summary = []
        for eid in email_ids[-10:]:
            status, msg_data = mail.fetch(eid, '(RFC822.HEADER)')
            if msg_data and msg_data[0]:
                msg = email.message_from_bytes(msg_data[0][1])
                
                # 提取信息
                subject = decode_mime_words(msg.get('Subject', ''))
                from_ = decode_mime_words(msg.get('From', ''))
                date_str = msg.get('Date', '')
                
                # 解析日期
                try:
                    date_obj = email.utils.parsedate_to_datetime(date_str)
                    date_formatted = date_obj.strftime('%Y-%m-%d %H:%M')
                except:
                    date_formatted = date_str
                
                # 检查是否紧急（标题包含关键词）
                urgent_keywords = ['紧急', 'urgent', '重要', 'important', 'asap', '立刻', '立即']
                is_urgent = any(kw.lower() in subject.lower() for kw in urgent_keywords)
                
                emails_summary.append({
                    'subject': subject[:100],
                    'from': from_[:50],
                    'date': date_formatted,
                    'urgent': is_urgent
                })
        
        mail.close()
        mail.logout()
        
        urgent_count = sum(1 for e in emails_summary if e['urgent'])
        
        return {
            'status': 'ok',
            'unread_count': len(email_ids),
            'urgent_count': urgent_count,
            'emails': emails_summary,
            'message': f'发现 {len(email_ids)} 封未读邮件' + (f' ({urgent_count} 封紧急)' if urgent_count else '')
        }
        
    except Exception as e:
        return {
            'status': 'error',
            'error': str(e),
            'message': f'邮件检查失败：{str(e)}'
        }

def main():
    # 从环境变量或配置文件读取配置
    config = {
        'host': os.environ.get('EMAIL_IMAP_HOST', 'imap.example.com'),
        'port': int(os.environ.get('EMAIL_IMAP_PORT', '993')),
        'email': os.environ.get('EMAIL_ADDRESS', ''),
        'password': os.environ.get('EMAIL_PASSWORD', '')
    }
    
    # 检查是否有配置文件
    config_file = os.path.join(os.path.dirname(__file__), 'email-config.json')
    if os.path.exists(config_file):
        with open(config_file, 'r', encoding='utf-8') as f:
            file_config = json.load(f)
            config.update(file_config)
    
    if not config['email'] or not config['password']:
        print(json.dumps({
            'status': 'error',
            'message': '未配置邮箱账号和密码。请设置环境变量或创建 email-config.json 配置文件'
        }, ensure_ascii=False))
        sys.exit(1)
    
    # 检查邮件
    result = check_email(config)
    
    # 输出 JSON 结果
    print(json.dumps(result, ensure_ascii=False))
    
    # 如果有紧急邮件，退出码设为 1 以触发通知
    if result.get('urgent_count', 0) > 0:
        sys.exit(1)
    sys.exit(0)

if __name__ == '__main__':
    main()
