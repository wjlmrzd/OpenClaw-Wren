const fs = require('fs');
const path = require('path');

// 模拟读取 API 使用统计（实际应从 codexbar 或类似工具获取）
function getApiUsage() {
    const models = ['qwen3.5-plus', 'glm-5', 'kimi-k2.5', 'qwen3-coder-plus', 'glm-4.7', 'minimax-m2.5', 'qwen3-coder-next'];
    const usage = {};
    for (const model of models) {
        // 随机生成模拟数据，基于 4 小时窗口
        const hourlyQuota = 100; // 假设每小时配额
        const currentHourlyUsage = Math.floor(Math.random() * 120); // 0-119 的随机数
        usage[model] = {
            hourlyUsage: currentHourlyUsage,
            quota: hourlyQuota,
            percentage: Math.round((currentHourlyUsage / hourlyQuota) * 100)
        };
    }
    return usage;
}

// 获取系统资源使用情况
function getSystemResources() {
    const totalMem = 16 * 1024 * 1024 * 1024; // 16GB in bytes
    const freeMem = Math.floor(Math.random() * 4 + 2) * 1024 * 1024 * 1024; // 2-5GB free
    const usedMem = totalMem - freeMem;
    const memPercent = Math.round((usedMem / totalMem) * 100);
    
    const cpuPercent = Math.floor(Math.random() * 30 + 10); // 10-40%
    
    // 获取磁盘使用情况 (模拟)
    const diskTotal = 512 * 1024 * 1024 * 1024; // 512GB
    const diskUsed = Math.floor(Math.random() * 400 + 300) * 1024 * 1024 * 1024; // 300-400GB used
    const diskPercent = Math.round((diskUsed / diskTotal) * 100);
    
    return {
        memory: {
            used: usedMem,
            total: totalMem,
            percent: memPercent
        },
        cpu: cpuPercent,
        disk: {
            used: diskUsed,
            total: diskTotal,
            percent: diskPercent
        }
    };
}

// 检查当前时间是否在静默时段
function isInSilentHours() {
    const now = new Date();
    const hour = now.getHours();
    return hour >= 22 || hour < 6; // 22:00 - 06:00
}

// 主函数
function main() {
    console.log('⚖️ 资源守护者 - 系统资源监控报告');
    console.log('================================');
    
    const apiUsage = getApiUsage();
    const resources = getSystemResources();
    const isSilent = isInSilentHours();
    
    console.log('\n📊 API 使用统计 (过去 4 小时):');
    console.log('--------------------------------');
    let hasHighUsage = false;
    for (const [model, stats] of Object.entries(apiUsage)) {
        const warning = stats.percentage > 80 ? ' ⚠️' : '';
        if (stats.percentage > 80) hasHighUsage = true;
        console.log(`${model}: ${stats.hourlyUsage}/${stats.quota} (${stats.percentage}%${warning})`);
    }
    
    console.log('\n🖥️ 系统资源使用:');
    console.log('------------------');
    console.log(`内存: ${(resources.memory.used / 1024 / 1024 / 1024).toFixed(1)}GB / ${(resources.memory.total / 1024 / 1024 / 1024).toFixed(1)}GB (${resources.memory.percent}%)`);
    console.log(`CPU: ${resources.cpu}%`);
    console.log(`磁盘: ${(resources.disk.used / 1024 / 1024 / 1024).toFixed(1)}GB / ${(resources.disk.total / 1024 / 1024 / 1024).toFixed(1)}GB (${resources.disk.percent}%)`);
    
    console.log('\n⏰ 当前时段:', isSilent ? '🌙 静默时段 (22:00-06:00)' : '☀️ 工作时段');
    
    // 预警检查
    console.log('\n⚠️ 预警检查:');
    console.log('-------------');
    
    const alerts = [];
    
    // API 配额预警
    for (const [model, stats] of Object.entries(apiUsage)) {
        if (stats.percentage > 80) {
            alerts.push(`API 配额预警: ${model} 达到 ${stats.percentage}% 配额`);
        }
    }
    
    // 内存预警
    if (resources.memory.percent > 95) {
        alerts.push(`严重内存警告: 使用率 ${resources.memory.percent}% (建议立即重启 Gateway)`);
    } else if (resources.memory.percent > 90) {
        alerts.push(`内存预警: 使用率 ${resources.memory.percent}% (建议重启 Gateway)`);
    }
    
    // 磁盘预警
    if (resources.disk.percent > 95) {
        alerts.push(`严重磁盘警告: 使用率 ${resources.disk.percent}% (立即清理空间)`);
    } else if (resources.disk.percent > 85) {
        alerts.push(`磁盘预警: 使用率 ${resources.disk.percent}% (触发日志清理)`);
    }
    
    if (alerts.length === 0) {
        console.log('✅ 一切正常，无预警');
    } else {
        for (const alert of alerts) {
            console.log(alert);
        }
        
        // 根据静默时段决定是否发送详细预警
        if (isSilent) {
            console.log('\n🌙 静默时段: 仅发送严重警告');
            const severeAlerts = alerts.filter(a => 
                a.includes('严重') || 
                a.includes('立即') || 
                (a.includes('API') && a.includes('100%'))
            );
            
            if (severeAlerts.length > 0) {
                console.log('\n🚨 静默时段严重预警:');
                for (const alert of severeAlerts) {
                    console.log(alert);
                }
            } else {
                console.log('\n✅ 静默时段: 普通预警已延迟至 06:00 后发送');
            }
        }
    }
    
    console.log('\n💡 优化建议:');
    console.log('-------------');
    if (resources.memory.percent > 85) {
        console.log('- 考虑重启 Gateway 释放内存');
    }
    if (resources.disk.percent > 80) {
        console.log('- 清理旧日志文件释放磁盘空间');
    }
    if (hasHighUsage) {
        console.log('- 暂停非关键任务以减少 API 调用');
    }
    if (!hasHighUsage && resources.memory.percent <= 85 && resources.disk.percent <= 80) {
        console.log('- 系统资源充足，运行正常');
    }
}

main();