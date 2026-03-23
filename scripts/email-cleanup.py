#!/usr/bin/env python3
"""
邮件清理脚本 - 批量标记未读邮件为已读
用于清理未读邮件积压
"""

import imaplib
import json
import os
import sys
import time

def cleanup_unread_emails(config, batch_size=20):
    """
    清理未读邮件 - 分批处理避免超时
    
    Args:
        config: 邮箱配置
        batch_size: 每批处理的邮件数量
    
    Returns:
        清理结果
    """
    try:
        # 连接 IMAP 服务器（设置超时）
        print(f"正在连接到 {config['host']}...")
        mail = imaplib.IMAP4_SSL(config['host'], config['port'], timeout=60)
        
        # 登录
        print(f"正在登录 {config['email']}...")
        mail.login(config['email'], config['password'])
        print("登录成功")
        
        # 选择收件箱
        mail.select('INBOX')
        
        # 搜索未读邮件 - 使用 UID
        status, messages = mail.uid('search', None, 'UNSEEN')
        email_ids = messages[0].split()
        
        unread_count = len(email_ids)
        
        if unread_count == 0:
            print("✅ 没有未读邮件需要清理")
            return {
                'status': 'ok',
                'marked_count': 0,
                'message': '没有未读邮件需要清理'
            }
        
        print(f"发现 {unread_count} 封未读邮件")
        print(f"将分 {((unread_count + batch_size - 1) // batch_size)} 批处理，每批 {batch_size} 封")
        
        # 分批标记为已读
        total_marked = 0
        for i in range(0, len(email_ids), batch_size):
            batch = email_ids[i:i+batch_size]
            batch_num = (i // batch_size) + 1
            print(f"  处理第 {batch_num} 批 ({len(batch)} 封)...")
            
            # 使用 UID STORE 命令标记为已读
            id_range = b','.join(batch)
            status, result = mail.uid('store', id_range, '+FLAGS', b'(\\Seen)')
            
            if status == 'OK':
                total_marked += len(batch)
                print(f"    ✓ 本批完成")
            else:
                print(f"    ⚠ 本批部分失败：{result}")
            
            # 短暂等待避免服务器限制
            time.sleep(0.3)
        
        print(f"✅ 已将 {total_marked}/{unread_count} 封邮件标记为已读")
        
        mail.close()
        mail.logout()
        
        return {
            'status': 'ok',
            'marked_count': total_marked,
            'total_unread': unread_count,
            'message': f'已将 {total_marked}/{unread_count} 封未读邮件标记为已读'
        }
        
    except Exception as e:
        print(f"❌ 错误：{str(e)}")
        return {
            'status': 'error',
            'error': str(e),
            'message': f'清理失败：{str(e)}'
        }

def main():
    # 读取配置
    config_file = os.path.join(os.path.dirname(__file__), 'email-config.json')
    if not os.path.exists(config_file):
        print("❌ 配置文件不存在：email-config.json")
        sys.exit(1)
    
    with open(config_file, 'r', encoding='utf-8') as f:
        config = json.load(f)
    
    # 执行清理
    result = cleanup_unread_emails(config, batch_size=20)
    
    # 输出结果
    print(json.dumps(result, ensure_ascii=False, indent=2))
    
    if result['status'] == 'ok':
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == '__main__':
    main()
