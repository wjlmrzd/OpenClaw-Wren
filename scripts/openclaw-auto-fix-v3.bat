@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: OpenClaw Auto-Fix v3
:: Loads sensitive data from .env file

set SCRIPTDIR=%~dp0
set LOGDIR=C:\Users\Administrator\.openclaw\logs
set LOGFILE=%LOGDIR%\auto-fix-v3.log

:: Load environment variables
call "%SCRIPTDIR%load-env.bat"
if %errorlevel% neq 0 (
    echo ERROR: Failed to load .env file
    exit /b 1
)

:: Use env variables
set BOTTOKEN=%TELEGRAM_BOT_TOKEN%
set CHATID=%TELEGRAM_CHAT_ID%
set BRAVEKEY=%BRAVE_SEARCH_API_KEY%

set CONFIGBACKUP=%LOGDIR%\config-backup-%date:~0,4%%date:~5,2%%date:~8,2%-%time:~0,2%%time:~3,2%%time:~6,2%.json

if not exist "%LOGDIR%" mkdir "%LOGDIR%"

for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value ^| find "="') do set dt=%%a
set TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2% %dt:~8,2%:%dt:~10,2%

echo [%TIMESTAMP%] === OpenClaw Auto-Fix v3 Started === >> "%LOGFILE%"
echo [%TIMESTAMP%] Environment loaded from .env >> "%LOGFILE%"

set FIXES=0
set ERRORS=0
set DOCTORFIXED=0

:: ========== STEP 1: Backup Config ==========
echo [%TIMESTAMP%] Backing up config... >> "%LOGFILE%"
if exist "%USERPROFILE%\.openclaw\openclaw.json" (
    copy "%USERPROFILE%\.openclaw\openclaw.json" "%CONFIGBACKUP%" >nul 2>&1
    echo [%TIMESTAMP%] Config backed up >> "%LOGFILE%"
)

:: ========== STEP 2: Run Doctor --fix ==========
echo [%TIMESTAMP%] Running doctor --fix... >> "%LOGFILE%"
openclaw doctor --fix --non-interactive > "%LOGDIR%\doctor-output.txt" 2>&1
if %errorlevel% neq 0 set DOCTORFIXED=1

:: ========== STEP 3: Check & Restart Gateway ==========
echo [%TIMESTAMP%] Checking gateway... >> "%LOGFILE%"
openclaw gateway status >nul 2>&1
if %errorlevel% neq 0 (
    echo [%TIMESTAMP%] Gateway down, restarting... >> "%LOGFILE%"
    openclaw gateway stop >nul 2>&1
    timeout /t 2 >nul
    openclaw gateway start >nul 2>&1
    timeout /t 3 >nul
    
    openclaw gateway status >nul 2>&1
    if %errorlevel% == 0 (
        echo [%TIMESTAMP%] Gateway restarted >> "%LOGFILE%"
        set /a FIXES+=1
    ) else (
        echo [%TIMESTAMP%] Force restarting... >> "%LOGFILE%"
        taskkill /f /im openclaw.exe >nul 2>&1
        timeout /t 2 >nul
        openclaw gateway start >nul 2>&1
        set /a FIXES+=1
    )
)

:: ========== STEP 4: Git Sync ==========
if exist "%USERPROFILE%\.openclaw\workspace\.git" (
    cd /d "%USERPROFILE%\.openclaw\workspace"
    git add . >nul 2>&1
    git commit -m "Auto-fix: %TIMESTAMP%" >nul 2>&1
    git push origin master >nul 2>&1
)

:: ========== STEP 5: Send Report ==========
set REPORT=OpenClaw Auto-Fix v3 Report
set REPORT=%REPORT%`nTime: %TIMESTAMP%
set REPORT=%REPORT%`nFixes: %FIXES%
set REPORT=%REPORT%`nErrors: %ERRORS%
if %ERRORS% == 0 (set REPORT=%REPORT%`nStatus: OK) else (set REPORT=%REPORT%`nStatus: NEEDS ATTENTION)

powershell -Command "try { Invoke-RestMethod -Uri 'https://api.telegram.org/bot%BOTTOKEN%/sendMessage' -Method Post -Body @{chat_id='%CHATID%';text='%REPORT%'} -ContentType 'application/x-www-form-urlencoded' -TimeoutSec 30 } catch {}" >nul 2>&1

echo [%TIMESTAMP%] === Auto-Fix v3 Completed === >> "%LOGFILE%"
echo. >> "%LOGFILE%"

exit /b %ERRORS%
