# 统计每5小时 MiniMax (minimax-2.7) 调用次数

$tasks = @(
    @{name='📡 事件协调员'; per5h=60},      # 每5分钟 = 5*12=60
    @{name='🏥 健康监控员'; per5h=10},       # 每30分钟 = 10
    @{name='🤖 伴侣检查员'; per5h=5},        # 每小时 = 5
    @{name='🚑 故障自愈员'; per5h=5},        # 每小时 = 5
    @{name='📧 邮件监控员'; per5h=2},        # 每3小时 = 2
    @{name='⚖️ 资源守护者'; per5h=3},        # 每2小时 = 3
    @{name='🔔 通知协调员'; per5h=2},        # 每3小时 = 2
    @{name='📝 配置审计师'; per5h=2},        # 每4小时 = 2 (但每5小时是1.25≈2)
    @{name='💰 成本追踪员'; per5h=1},        # 每6小时 = 1
    @{name='📡 RSS 监控'; per5h=1},         # 每6小时 = 1
    @{name='🛡️ 安全审计员'; per5h=3},        # 每2小时 = 3
    @{name='🏃 跑步提醒(早)'; per5h=1},      # 每天1次
    @{name='💼 项目顾问'; per5h=1},           # 每天1次
    @{name='📊 运营总监'; per5h=1},          # 每周1次(每5小时≈0.2≈1)
    @{name='Obsidian Config'; per5h=1}       # 每天1次
)

$fixed = @(
    @{name='⚙️ 配置优化员'; per5h=1},
    @{name='🧹 日志清理员'; per5h=1},
    @{name='🧬 知识演化员'; per5h=1},
    @{name='🏃 运动提醒员'; per5h=1},
    @{name='📰 每日早报'; per5h=1},
    @{name='🌐 网站监控员'; per5h=1},
    @{name='📰 每日信息汇总'; per5h=1},
    @{name='📈 每周总结'; per5h=1},
    @{name='📊 每周训练回顾'; per5h=1},
    @{name='💰 成本分析师'; per5h=1},
    @{name='🚨 灾难恢复官'; per5h=1},
    @{name='🧪 灾难演练员'; per5h=1}
)

$all = $tasks + $fixed

Write-Host "=== MiniMax (minimax-2.7) 每5小时调用统计 ===" -ForegroundColor Cyan
Write-Host ""

$total = 0
foreach ($t in $all) {
    Write-Host "$($t.name): $($t.per5h) 次/5h" -ForegroundColor Green
    $total += $t.per5h
}

Write-Host ""
Write-Host "总计: $total 次/5小时" -ForegroundColor Yellow
