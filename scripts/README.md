# OpenClaw 运维手册

## 快速开始

### 1. 启动运维控制台
```powershell
cd D:\OpenClaw\.openclaw\workspace\scripts
.\unified-maintenance-console.ps1
```

### 2. 查看系统仪表盘
直接在浏览器中打开 `system-dashboard.html`:
```
D:\OpenClaw\.openclaw\workspace\scripts\system-dashboard.html
```

### 3. 快速启动菜单
双击运行 `quick-start.bat`，选择对应功能:
```batch
scripts\quick-start.bat
```

---

## 日常运维

### 每日检查
1. 系统状态 → 查看资源使用、Gateway 状态
2. 健康检查 → 运行完整健康检查
3. 查看事件 → 检查最近事件日志

### 定期任务
- **日志清理**: 每周执行，删除 7 天前的日志
- **配置备份**: 每天自动备份
- **任务检查**: 查看 Cron 任务执行状态

### 故障处理
参考 [故障排查](#故障排查) 章节

---

## 目录结构

```
scripts/
├── unified-maintenance-console.ps1   # 主控制台入口
├── system-dashboard.html              # Web 仪表盘
├── quick-start.bat                     # 快速启动脚本
├── modules/                           # 子模块
│   ├── system-status.ps1              # 系统状态
│   ├── log-manager.ps1                # 日志管理
│   ├── task-manager.ps1                # 任务管理
│   ├── backup-manager.ps1              # 备份管理
│   ├── automation-tools.ps1           # 自动化工具
│   └── info-collector.ps1             # 信息采集
└── README.md                          # 本文档
```

---

## 常用命令

| 操作 | 命令 |
|------|------|
| 查看 Gateway 状态 | `openclaw gateway status` |
| 重启 Gateway | `openclaw gateway restart` |
| 列出 Cron 任务 | `openclaw cron list` |
| 运行指定任务 | `openclaw cron run --id "xxx"` |
| 查看任务详情 | `openclaw cron info --id "xxx"` |
| 启用任务 | `openclaw cron enable --id "xxx"` |
| 禁用任务 | `openclaw cron disable --id "xxx"` |
| 运行健康检查 | `openclaw health-check` |
| 运行安全扫描 | `openclaw security scan` |

---

## 功能模块

### 1. 系统状态
查看系统资源使用情况:
- Gateway 运行状态
- CPU 使用率
- 内存使用率
- 磁盘使用率
- 最近事件日志

### 2. 健康检查
运行完整系统健康检查:
- Gateway 服务状态
- 配置文件检查
- 磁盘空间检查
- Cron 任务状态
- 安全设置检查

### 3. 日志管理
- 查看日志列表
- 实时查看日志内容
- 清理指定天数前的日志
- 压缩归档日志
- 导出日志到指定位置
- 日志大小统计

### 4. 任务管理
- 列出所有 Cron 任务
- 查看任务详细信息
- 手动运行指定任务
- 启用/禁用任务
- 查看任务执行历史
- 刷新任务状态

### 5. 安全扫描
- 检查配置安全
- 扫描敏感信息
- 生成安全报告

### 6. 备份管理
- 创建配置备份
- 列出所有备份
- 从备份恢复配置
- 删除备份
- 导出备份到其他位置
- 配置自动备份

### 7. 自动化工具

#### Word 处理
- 创建 Word 文档
- 读取 Word 文档
- 批量转换到 PDF

#### Excel 处理
- 创建 Excel 工作簿
- 读取 Excel 数据
- CSV/Excel 数据导入导出

#### PDF 处理
- 合并 PDF 文件
- 拆分 PDF 文件
- PDF 转图片

#### 文件处理
- 批量重命名
- 批量压缩/解压
- 文件查找
- 目录同步

### 8. 信息采集

#### RSS 阅读
- 添加 RSS 源
- 查看 RSS 列表
- 读取订阅内容
- 删除 RSS 源

#### 关键词监控
- 添加监控关键词
- 查看关键词列表
- 执行关键词搜索
- 删除关键词

#### 网站监控
- 添加监控网站
- 查看监控列表
- 批量检查网站状态

### 9. 配置管理
- 编辑配置文件
- 重启 Gateway 服务
- 查看配置状态

---

## 故障排查

### 1. Gateway 无法启动

**症状**: `openclaw gateway start` 失败

**排查步骤**:
1. 检查端口占用: `netstat -ano | findstr 8080`
2. 查看错误日志: `Get-Content $env:USERPROFILE\.openclaw\logs\*.log -Tail 50`
3. 检查配置文件: `config.yaml` 语法是否正确
4. 尝试重启服务: `openclaw gateway restart`

**解决方案**:
- 如果端口被占用，结束对应进程或修改配置端口
- 如果配置错误，恢复备份配置
- 如果日志显示其他错误，根据错误信息进一步排查

### 2. Cron 任务失败

**症状**: 任务执行失败或卡住

**排查步骤**:
1. 查看任务日志: `openclaw cron log --id "xxx"`
2. 检查任务状态: `openclaw cron list`
3. 手动运行测试: `openclaw cron run --id "xxx"`
4. 检查任务配置是否正确

**解决方案**:
- 如果是网络问题，检查网络连接
- 如果是配置错误，修正任务配置
- 如果是权限问题，检查执行权限
- 禁用并重新启用任务

### 3. 通知未发送

**症状**: 通知功能不工作

**排查步骤**:
1. 检查 Telegram 配置: `config.yaml` 中的 bot token
2. 测试网络连接: `Test-NetConnection tg-bot.shuangxian.com`
3. 查看通知日志
4. 验证接收者 ID

**解决方案**:
- 重新配置 Telegram bot token
- 检查网络代理设置
- 验证 bot 权限和接收者 ID

### 4. 磁盘空间不足

**症状**: 系统提示磁盘空间不足

**排查步骤**:
1. 检查磁盘使用: `Get-PSDrive C`
2. 查看日志大小: `modules/log-manager.ps1` → 日志统计
3. 查找大文件: `Get-ChildItem -Recurse | Sort-Object Length -Descending | Select-Object -First 20`

**解决方案**:
- 清理旧日志: `modules/log-manager.ps1` → 清理旧日志
- 清理临时文件: `Remove-Item $env:TEMP\* -Recurse -Force`
- 删除不需要的备份
- 清理插件缓存

---

## 配置文件位置

| 配置文件 | 路径 |
|----------|------|
| 主配置 | `$env:USERPROFILE\.openclaw\config.yaml` |
| 密钥配置 | `$env:USERPROFILE\.openclaw\secrets.yaml` |
| Agent 配置 | `$env:USERPROFILE\.openclaw\agents.yaml` |
| 日志目录 | `$env:USERPROFILE\.openclaw\logs\` |
| 备份目录 | `$env:USERPROFILE\.openclaw\backups\` |
| 数据目录 | `$env:USERPROFILE\.openclaw\data\` |

---

## 系统要求

- Windows 10/11 或 Windows Server 2019+
- PowerShell 5.1+
- Node.js 18+ (用于 OpenClaw)
- 网络连接 (用于通知和 RSS 功能)

---

## 获取帮助

- 查看 GitHub: https://github.com/your-repo/openclaw
- 查看文档: `docs/` 目录
- 联系支持: @your_username

---

*最后更新: 2025-01-20*
