@echo off
:: OpenClaw Service Wrapper v2
:: Uses doctor --fix before restart

chcp 65001 >nul
set LOGDIR=C:\Users\Administrator\.openclaw\logs
set LOGFILE=%LOGDIR%\service-wrapper-v2.log
set CHECK_INTERVAL=30

if not exist "%LOGDIR%" mkdir "%LOGDIR%"

:main_loop
for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value ^| find "="') do set dt=%%a
set TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2% %dt:~8,2%:%dt:~10,2%

:: Check gateway
timeout /t %CHECK_INTERVAL% >nul
openclaw gateway status >nul 2>&1
if %errorlevel% neq 0 (
    echo [%TIMESTAMP%] Gateway down detected, running auto-fix... >> "%LOGFILE%"
    call "%~dp0openclaw-auto-fix-v2.bat" >nul 2>&1
)

goto :main_loop
