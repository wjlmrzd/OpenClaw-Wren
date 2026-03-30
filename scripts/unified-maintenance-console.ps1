# OpenClaw 运维管理控制台 v1.0
# 统一入口 - 调用各子模块

param(
    [string]$Module
)

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModuleDir = Join-Path $ScriptDir "modules"

function Show-Menu {
    Clear-Host
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗"
    Write-Host "║           OpenClaw 运维管理控制台 v1.0                         ║"
    Write-Host "╠══════════════════════════════════════════════════════════════╣"
    Write-Host "║  1. 系统状态        - 查看资源使用、Gateway 状态               ║"
    Write-Host "║  2. 健康检查        - 运行完整健康检查                         ║"
    Write-Host "║  3. 日志管理        - 清理、压缩、导出日志                      ║"
    Write-Host "║  4. 任务管理        - 查看、重启、禁用 Cron 任务               ║"
    Write-Host "║  5. 安全扫描        - 运行安全审计                            ║"
    Write-Host "║  6. 备份管理        - 备份配置、历史记录                       ║"
    Write-Host "║  7. 自动化工具      - Word/Excel/PDF/文件处理                  ║"
    Write-Host "║  8. 信息采集        - RSS、关键词、网站监控                     ║"
    Write-Host "║  9. 配置管理        - 编辑配置、重启服务                       ║"
    Write-Host "║  0. 退出                                                     ║"
    Write-Host "╚══════════════════════════════════════════════════════════════╝"
    Write-Host ""
}

function Invoke-Module {
    param([string]$Name)
    $modulePath = Join-Path $ModuleDir "$Name.ps1"
    if (Test-Path $modulePath) {
        & $modulePath
    } else {
        Write-Host "[警告] 模块不存在: $Name" -ForegroundColor Yellow
        Write-Host "按任意键继续..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

# Direct module execution mode
if ($Module) {
    Invoke-Module -Name $Module
    exit
}

# Interactive menu mode
do {
    Show-Menu
    $choice = Read-Host "请选择操作 (0-9)"
    
    switch ($choice) {
        "1" { Invoke-Module -Name "system-status" }
        "2" { 
            Write-Host "运行健康检查..." -ForegroundColor Cyan
            openclaw health-check
            Write-Host "按任意键继续..." -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "3" { Invoke-Module -Name "log-manager" }
        "4" { Invoke-Module -Name "task-manager" }
        "5" { 
            Write-Host "运行安全扫描..." -ForegroundColor Cyan
            openclaw security scan
            Write-Host "按任意键继续..." -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "6" { Invoke-Module -Name "backup-manager" }
        "7" { Invoke-Module -Name "automation-tools" }
        "8" { Invoke-Module -Name "info-collector" }
        "9" { 
            Write-Host "打开配置编辑器..." -ForegroundColor Cyan
            code $env:USERPROFILE\.openclaw\config.yaml
            Write-Host "按任意键继续..." -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "0" { 
            Write-Host "再见!" -ForegroundColor Green
            exit 
        }
        default { 
            Write-Host "无效选择，请重新输入" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($choice -ne "0")
