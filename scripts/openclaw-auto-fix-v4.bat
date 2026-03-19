@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: OpenClaw Auto-Fix v4
:: Manual push only - no automatic GitHub sync

set SCRIPTDIR=%~dp0
set LOGDIR=C:\Users\Administrator\.openclaw\logs
set LOGFILE=%LOGDIR%\auto-fix-v4.log

:: Load secure environment variables
call "%SCRIPTDIR%load-secure-env.bat"
if %errorlevel% neq 0 (
    echo [%date% %time%] ERROR: Failed to load secure env >> "%LOGFILE%"
    exit /b 1
)

set CONFIGBACKUP=%LOGDIR%\config-backup-%date:~0,4%%date:~5,2%%date:~8,2%-%time:~0,2%%time:~3,2%%time:~6,2%.json

if not exist "%LOGDIR%" mkdir "%LOGDIR%"

for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value ^| find "="') do set dt=%%a
set TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2% %dt:~8,2%:%dt:~10,2%

echo [%TIMESTAMP%] === OpenClaw Auto-Fix v4 Started === >> "%LOGFILE%"
echo [%TIMESTAMP%] Secure environment loaded >> "%LOGFILE%"

set FIXES=0
set ERRORS=0
set DOCTORFIXED=0

:: ========== STEP 1: Backup Config ==========
echo [%TIMESTAMP%] Backing up config... >> "%LOGFILE%"
if exist "%USERPROFILE%\.openclaw\openclaw.json" (
    copy "%USERPROFILE%\.openclaw\openclaw.json" "%CONFIGBACKUP%" >nul 2>&1
    echo [%TIMESTAMP%] Config backed up to: %CONFIGBACKUP% >> "%LOGFILE%"
)

:: ========== STEP 2: Run Doctor --fix ==========
echo [%TIMESTAMP%] Running openclaw doctor --fix... >> "%LOGFILE%"
openclaw doctor --fix --non-interactive > "%LOGDIR%\doctor-output.txt" 2>&1
if %errorlevel% neq 0 (
    set DOCTORFIXED=1
    echo [%TIMESTAMP%] Doctor fixed issues >> "%LOGFILE%"
) else (
    echo [%TIMESTAMP%] Doctor: No issues found >> "%LOGFILE%"
)

:: ========== STEP 3: Check & Restart Gateway ==========
echo [%TIMESTAMP%] Checking gateway... >> "%LOGFILE%"
openclaw gateway status >nul 2>&1
if %errorlevel% neq 0 (
    echo [%TIMESTAMP%] Gateway NOT RUNNING >> "%LOGFILE%"
    
    echo [%TIMESTAMP%] Stopping gateway... >> "%LOGFILE%"
    openclaw gateway stop >nul 2>&1
    timeout /t 2 >nul
    
    echo [%TIMESTAMP%] Starting gateway... >> "%LOGFILE%"
    openclaw gateway start >nul 2>&1
    timeout /t 3 >nul
    
    openclaw gateway status >nul 2>&1
    if %errorlevel% == 0 (
        echo [%TIMESTAMP%] Gateway: RESTARTED >> "%LOGFILE%"
        set /a FIXES+=1
    ) else (
        echo [%TIMESTAMP%] Normal restart failed, trying force... >> "%LOGFILE%"
        taskkill /f /im openclaw.exe >nul 2>&1
        timeout /t 2 >nul
        openclaw gateway start >nul 2>&1
        timeout /t 3 >nul
        
        openclaw gateway status >nul 2>&1
        if %errorlevel% == 0 (
            echo [%TIMESTAMP%] Gateway: FORCE RESTARTED >> "%LOGFILE%"
            set /a FIXES+=1
        ) else (
            echo [%TIMESTAMP%] ERROR: Force restart failed >> "%LOGFILE%"
            set /a ERRORS+=1
        )
    )
) else (
    echo [%TIMESTAMP%] Gateway: RUNNING >> "%LOGFILE%"
    
    :: If doctor fixed something, do graceful restart
    if %DOCTORFIXED% == 1 (
        echo [%TIMESTAMP%] Restarting to apply doctor fixes... >> "%LOGFILE%"
        openclaw gateway restart >nul 2>&1
        timeout /t 3 >nul
        set /a FIXES+=1
    )
)

:: ========== STEP 4: System Verification ==========
echo [%TIMESTAMP%] Verifying system... >> "%LOGFILE%"

if exist "%USERPROFILE%\.openclaw\openclaw.json" (
    echo [%TIMESTAMP%] Config: OK >> "%LOGFILE%"
) else (
    echo [%TIMESTAMP%] ERROR: Config missing >> "%LOGFILE%"
    set /a ERRORS+=1
)

if exist "%USERPROFILE%\.openclaw\workspace" (
    echo [%TIMESTAMP%] Workspace: OK >> "%LOGFILE%"
) else (
    echo [%TIMESTAMP%] Creating workspace... >> "%LOGFILE%"
    mkdir "%USERPROFILE%\.openclaw\workspace"
    set /a FIXES+=1
)

:: ========== STEP 5: Send Telegram Report ==========
echo [%TIMESTAMP%] Sending report... >> "%LOGFILE%"

set REPORT=OpenClaw Auto-Fix v4 Report
set REPORT=%REPORT%`nTime: %TIMESTAMP%
set REPORT=%REPORT%`nDoctor fixes: %DOCTORFIXED%
set REPORT=%REPORT%`nGateway restarts: %FIXES%
set REPORT=%REPORT%`nErrors: %ERRORS%

if %ERRORS% == 0 (
    set REPORT=%REPORT%`nStatus: All systems operational
) else (
    set REPORT=%REPORT%`nStatus: ATTENTION REQUIRED
)

set REPORT=%REPORT%`n`nNote: Git push is MANUAL only

powershell -Command "try { Invoke-RestMethod -Uri 'https://api.telegram.org/bot%TELEGRAM_BOT_TOKEN%/sendMessage' -Method Post -Body @{chat_id='%TELEGRAM_CHAT_ID%';text='%REPORT%'} -ContentType 'application/x-www-form-urlencoded' -TimeoutSec 30 } catch { $_.Exception.Message }" >nul 2>&1

echo [%TIMESTAMP%] === Auto-Fix v4 Completed === >> "%LOGFILE%"
echo. >> "%LOGFILE%"

exit /b %ERRORS%
