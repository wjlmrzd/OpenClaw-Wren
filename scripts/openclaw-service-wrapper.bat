@echo off
:: OpenClaw Service Wrapper
:: Keeps OpenClaw gateway running, auto-restarts on crash

chcp 6508 >nul
set LOGDIR=C:\Users\Administrator\.openclaw\logs
set LOGFILE=%LOGDIR%\service-wrapper.log
set RESTART_DELAY=5

if not exist "%LOGDIR%" mkdir "%LOGDIR%"

:main_loop
for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value ^| find "="') do set dt=%%a
set TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2% %dt:~8,2%:%dt:~10,2%

echo [%TIMESTAMP%] Service wrapper checking OpenClaw... >> "%LOGFILE%"

:: Check if gateway is running
openclaw gateway status >nul 2>&1
if %errorlevel% neq 0 (
    echo [%TIMESTAMP%] Gateway not running, starting... >> "%LOGFILE%"
    
    :: Run auto-fix first
    call "%~dp0openclaw-auto-fix.bat" >nul 2>&1
    
    :: Start gateway
    openclaw gateway start >nul 2>&1
    
    for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value ^| find "="') do set dt2=%%a
    set TIMESTAMP2=%dt2:~0,4%-%dt2:~4,2%-%dt2:~6,2% %dt2:~8,2%:%dt2:~10,2%
    
    timeout /t 3 >nul
    openclaw gateway status >nul 2>&1
    if %errorlevel% == 0 (
        echo [%TIMESTAMP2%] Gateway started successfully >> "%LOGFILE%"
    ) else (
        echo [%TIMESTAMP2%] ERROR: Failed to start gateway >> "%LOGFILE%"
    )
)

:: Wait before next check
timeout /t %RESTART_DELAY% >nul
goto :main_loop
