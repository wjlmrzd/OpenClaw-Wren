# 任务管理模块 - 查看、重启、禁用 Cron 任务
# 由 unified-maintenance-console.ps1 调用

$ErrorActionPreference = "Continue"

function Show-TaskMenu {
    Clear-Host
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗"
    Write-Host "║                    任务管理 v1.0                                ║"
    Write-Host "╠══════════════════════════════════════════════════════════════╣"
    Write-Host "║  1. 列出所有任务        - 查看所有 Cron 任务                    ║"
    Write-Host "║  2. 查看任务详情        - 查看单个任务的详细信息                 ║"
    Write-Host "║  3. 运行任务            - 手动执行指定任务                      ║"
    Write-Host "║  4. 启用/禁用任务       - 切换任务状态                          ║"
    Write-Host "║  5. 任务执行历史        - 查看任务执行记录                       ║"
    Write-Host "║  6. 刷新任务状态        - 重新加载任务列表                       ║"
    Write-Host "║  0. 返回                                                    ║"
    Write-Host "╚══════════════════════════════════════════════════════════════╝"
    Write-Host ""
}

function Get-TaskList {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Cron 任务列表" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        $tasks = openclaw cron list 2>&1
        Write-Host $tasks
    } catch {
        Write-Host "  无法获取任务列表: $_" -ForegroundColor Red
    }
    
    Write-Host ""
}

function Get-TaskDetail {
    Get-TaskList
    Write-Host ""
    $taskId = Read-Host "请输入任务 ID"
    if ([string]::IsNullOrWhiteSpace($taskId)) {
        Write-Host "  任务 ID 不能为空" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    Write-Host ""
    Write-Host ("  正在获取任务 {0} 的详情..." -f $taskId) -ForegroundColor Yellow
    Write-Host ""
    
    try {
        $detail = openclaw cron info --id $taskId 2>&1
        Write-Host $detail
    } catch {
        Write-Host "  获取详情失败: $_" -ForegroundColor Red
    }
    
    Read-Host "按 Enter 继续"
}

function Invoke-Task {
    Get-TaskList
    Write-Host ""
    $taskId = Read-Host "请输入要运行的任务 ID"
    if ([string]::IsNullOrWhiteSpace($taskId)) {
        Write-Host "  任务 ID 不能为空" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    Write-Host ""
    Write-Host ("  正在运行任务 {0}..." -f $taskId) -ForegroundColor Yellow
    
    try {
        $result = openclaw cron run --id $taskId 2>&1
        Write-Host $result
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  任务执行成功" -ForegroundColor Green
        } else {
            Write-Host "  任务执行失败" -ForegroundColor Red
        }
    } catch {
        Write-Host "  执行失败: $_" -ForegroundColor Red
    }
    
    Read-Host "按 Enter 继续"
}

function Set-TaskState {
    Get-TaskList
    Write-Host ""
    $taskId = Read-Host "请输入任务 ID"
    if ([string]::IsNullOrWhiteSpace($taskId)) {
        Write-Host "  任务 ID 不能为空" -ForegroundColor Red
        Read-Host "按 Enter 继续"
        return
    }
    
    Write-Host ""
    Write-Host "  1. 启用任务"
    Write-Host "  2. 禁用任务"
    $action = Read-Host "请选择操作"
    
    switch ($action) {
        "1" {
            Write-Host ("  正在启用任务 {0}..." -f $taskId) -ForegroundColor Yellow
            try {
                openclaw cron enable --id $taskId 2>&1
                Write-Host "  任务已启用" -ForegroundColor Green
            } catch {
                Write-Host "  操作失败: $_" -ForegroundColor Red
            }
        }
        "2" {
            Write-Host ("  正在禁用任务 {0}..." -f $taskId) -ForegroundColor Yellow
            try {
                openclaw cron disable --id $taskId 2>&1
                Write-Host "  任务已禁用" -ForegroundColor Green
            } catch {
                Write-Host "  操作失败: $_" -ForegroundColor Red
            }
        }
        default {
            Write-Host "  无效选择" -ForegroundColor Red
        }
    }
    
    Read-Host "按 Enter 继续"
}

function Get-TaskHistory {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  任务执行历史" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    $historyPath = Join-Path $env:USERPROFILE ".openclaw\logs\task_history.log"
    if (Test-Path $historyPath) {
        Get-Content $historyPath -Tail 20
    } else {
        Write-Host "  暂无执行历史" -ForegroundColor Gray
    }
    
    Write-Host ""
    Read-Host "按 Enter 继续"
}

function Refresh-Tasks {
    Write-Host ""
    Write-Host "  正在刷新任务列表..." -ForegroundColor Yellow
    
    try {
        openclaw cron reload 2>&1
        Write-Host "  刷新完成" -ForegroundColor Green
    } catch {
        Write-Host "  刷新失败: $_" -ForegroundColor Red
    }
    
    Read-Host "按 Enter 继续"
}

function Main {
    do {
        Show-TaskMenu
        $choice = Read-Host "请选择操作 (0-6)"
        
        switch ($choice) {
            "1" { Get-TaskList; Read-Host "按 Enter 继续" }
            "2" { Get-TaskDetail }
            "3" { Invoke-Task }
            "4" { Set-TaskState }
            "5" { Get-TaskHistory }
            "6" { Refresh-Tasks }
            "0" { return }
            default { 
                Write-Host "  无效选择" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($choice -ne "0")
}

Main
