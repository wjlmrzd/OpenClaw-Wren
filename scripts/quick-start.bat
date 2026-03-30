@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

echo =============================================================
echo                    OpenClaw 快速启动
echo =============================================================
echo.
echo   1. 启动运维控制台
echo   2. 打开系统仪表盘 (Web)
echo   3. 查看日志
echo   4. 健康检查
echo   5. 任务管理
echo   6. 备份管理
echo   7. 自动化工具
echo   8. 信息采集
echo   0. 退出
echo.
echo =============================================================
echo.

set /p choice=请选择 (0-8): 

if "%choice%"=="1" goto :console
if "%choice%"=="2" goto :dashboard
if "%choice%"=="3" goto :logs
if "%choice%"=="4" goto :health
if "%choice%"=="5" goto :tasks
if "%choice%"=="6" goto :backup
if "%choice%"=="7" goto :automation
if "%choice%"=="8" goto :info
if "%choice%"=="0" goto :exit

echo 无效选择，请重新输入
timeout /t 2 >nul
goto :start

:console
echo.
echo 正在启动运维控制台...
powershell -ExecutionPolicy Bypass -File "%~dp0unified-maintenance-console.ps1"
goto :end

:dashboard
echo.
echo 正在打开系统仪表盘...
start "" "%~dp0system-dashboard.html"
goto :end

:logs
echo.
echo 正在打开日志目录...
if exist "%USERPROFILE%\.openclaw\logs" (
    start explorer "%USERPROFILE%\.openclaw\logs"
) else (
    echo 日志目录不存在
)
goto :end

:health
echo.
echo 正在运行健康检查...
powershell -ExecutionPolicy Bypass -Command "& openclaw health-check; Read-Host '按 Enter 退出'"
goto :end

:tasks
echo.
echo 正在打开任务管理...
powershell -ExecutionPolicy Bypass -File "%~dp0modules\task-manager.ps1"
goto :end

:backup
echo.
echo 正在打开备份管理...
powershell -ExecutionPolicy Bypass -File "%~dp0modules\backup-manager.ps1"
goto :end

:automation
echo.
echo 正在打开自动化工具...
powershell -ExecutionPolicy Bypass -File "%~dp0modules\automation-tools.ps1"
goto :end

:info
echo.
echo 正在打开信息采集...
powershell -ExecutionPolicy Bypass -File "%~dp0modules\info-collector.ps1"
goto :end

:exit
echo.
echo 再见!
timeout /t 1 >nul
exit /b 0

:end
echo.
echo 按任意键返回...
pause >nul
