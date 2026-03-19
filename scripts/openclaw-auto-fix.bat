@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: OpenClaw Auto-Fix and Recovery Script
:: Runs on gateway restart or when issues detected

set LOGDIR=C:\Users\Administrator\.openclaw\logs
set LOGFILE=%LOGDIR%\auto-fix.log
set BOTTOKEN=8329757047:AAFxkpIJqkm-8HT1ZFz005tjFDeRRRIisH0
set CHATID=8542040756

if not exist "%LOGDIR%" mkdir "%LOGDIR%"

for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value ^| find "="') do set dt=%%a
set TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2% %dt:~8,2%:%dt:~10,2%

echo [%TIMESTAMP%] === OpenClaw Auto-Fix Started === >> "%LOGFILE%"

set FIXES=0
set ERRORS=0

:: 1. Check if OpenClaw is installed
echo [%TIMESTAMP%] Checking OpenClaw installation... >> "%LOGFILE%"
openclaw --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [%TIMESTAMP%] ERROR: OpenClaw not found >> "%LOGFILE%"
    set /a ERRORS+=1
    goto :send_report
)

:: 2. Check config file exists
if not exist "%USERPROFILE%\.openclaw\openclaw.json" (
    echo [%TIMESTAMP%] Config missing, running setup... >> "%LOGFILE%"
    openclaw setup --non-interactive
    set /a FIXES+=1
)

:: 3. Check gateway status
echo [%TIMESTAMP%] Checking gateway... >> "%LOGFILE%"
openclaw gateway status >nul 2>&1
if %errorlevel% neq 0 (
    echo [%TIMESTAMP%] Gateway down, attempting restart... >> "%LOGFILE%"
    openclaw gateway stop >nul 2>&1
    timeout /t 2 >nul
    openclaw gateway start >nul 2>&1
    timeout /t 3 >nul
    
    openclaw gateway status >nul 2>&1
    if %errorlevel% == 0 (
        echo [%TIMESTAMP%] Gateway restarted successfully >> "%LOGFILE%"
        set /a FIXES+=1
    ) else (
        echo [%TIMESTAMP%] ERROR: Gateway restart failed >> "%LOGFILE%"
        set /a ERRORS+=1
    )
) else (
    echo [%TIMESTAMP%] Gateway is running >> "%LOGFILE%"
)

:: 4. Check port conflicts
echo [%TIMESTAMP%] Checking port 18789... >> "%LOGFILE%"
netstat -ano | findstr :18789 >nul
if %errorlevel% == 0 (
    echo [%TIMESTAMP%] Port 18789 in use, checking if OpenClaw owns it... >> "%LOGFILE%"
    :: If gateway is running, it's fine. If not, there's a conflict.
    openclaw gateway status >nul 2>&1
    if %errorlevel% neq 0 (
        echo [%TIMESTAMP%] WARNING: Port conflict detected >> "%LOGFILE%"
    )
)

:: 5. Verify workspace exists
if not exist "%USERPROFILE%\.openclaw\workspace" (
    echo [%TIMESTAMP%] Workspace missing, creating... >> "%LOGFILE%"
    mkdir "%USERPROFILE%\.openclaw\workspace"
    set /a FIXES+=1
)

:: 6. Check logs directory
if not exist "%LOGDIR%" (
    mkdir "%LOGDIR%"
)

:: 7. Git sync (if configured)
if exist "%USERPROFILE%\.openclaw\workspace\.git" (
    echo [%TIMESTAMP%] Syncing with GitHub... >> "%LOGFILE%"
    cd /d "%USERPROFILE%\.openclaw\workspace"
    git add . >nul 2>&1
    git commit -m "Auto-backup: %TIMESTAMP%" >nul 2>&1
    git push origin master >nul 2>&1
    if %errorlevel% == 0 (
        echo [%TIMESTAMP%] Git sync completed >> "%LOGFILE%"
    ) else (
        echo [%TIMESTAMP%] Git sync skipped (no changes or offline) >> "%LOGFILE%"
    )
)

:send_report
:: Send report to Telegram
set REPORT=OpenClaw Auto-Fix Report
set REPORT=%REPORT%`nTime: %TIMESTAMP%
set REPORT=%REPORT%`nFixes applied: %FIXES%
set REPORT=%REPORT%`nErrors: %ERRORS%
set REPORT=%REPORT%`n`nStatus: 
if %ERRORS% == 0 (
    set REPORT=%REPORT%All systems operational
) else (
    set REPORT=%REPORT%Attention required
)

:: Use PowerShell to send Telegram message
echo [%TIMESTAMP%] Sending Telegram report... >> "%LOGFILE%"
powershell -Command "try { Invoke-RestMethod -Uri 'https://api.telegram.org/bot%BOTTOKEN%/sendMessage' -Method Post -Body @{chat_id='%CHATID%';text='%REPORT%'} -ContentType 'application/x-www-form-urlencoded' } catch {}" >nul 2>&1

echo [%TIMESTAMP%] === Auto-Fix Completed === >> "%LOGFILE%"
echo. >> "%LOGFILE%"

exit /b %ERRORS%
