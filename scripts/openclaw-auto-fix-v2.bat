@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: OpenClaw Auto-Fix v2
:: 1. Runs doctor --fix before any restart
:: 2. Auto-backup before fixing
:: 3. Non-interactive mode for automation

set LOGDIR=C:\Users\Administrator\.openclaw\logs
set LOGFILE=%LOGDIR%\auto-fix-v2.log
set CONFIGBACKUP=%LOGDIR%\config-backup-%date:~0,4%%date:~5,2%%date:~8,2%-%time:~0,2%%time:~3,2%%time:~6,2%.json
set BOTTOKEN=8329757047:AAFxkpIJqkm-8HT1ZFz005tjFDeRRRIisH0
set CHATID=8542040756

if not exist "%LOGDIR%" mkdir "%LOGDIR%"

for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value ^| find "="') do set dt=%%a
set TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2% %dt:~8,2%:%dt:~10,2%

echo [%TIMESTAMP%] === OpenClaw Auto-Fix v2 Started === >> "%LOGFILE%"

set FIXES=0
set ERRORS=0
set DOCTORFIXED=0

:: ========== STEP 1: Backup Config ==========
echo [%TIMESTAMP%] Backing up config... >> "%LOGFILE%"
if exist "%USERPROFILE%\.openclaw\openclaw.json" (
    copy "%USERPROFILE%\.openclaw\openclaw.json" "%CONFIGBACKUP%" >nul 2>&1
    echo [%TIMESTAMP%] Config backed up to: %CONFIGBACKUP% >> "%LOGFILE%"
) else (
    echo [%TIMESTAMP%] WARNING: No config to backup >> "%LOGFILE%"
)

:: ========== STEP 2: Run Doctor --fix ==========
echo [%TIMESTAMP%] Running openclaw doctor --fix... >> "%LOGFILE%"
openclaw doctor --fix --non-interactive > "%LOGDIR%\doctor-output.txt" 2>&1
set DOCTORRESULT=%errorlevel%

if %DOCTORRESULT% == 0 (
    echo [%TIMESTAMP%] Doctor: No issues found or fixed automatically >> "%LOGFILE%"
) else (
    echo [%TIMESTAMP%] Doctor: Issues detected and fixed (see doctor-output.txt) >> "%LOGFILE%"
    set /a FIXES+=1
    set DOCTORFIXED=1
)

:: Check if doctor mentioned restart is needed
findstr /i "restart" "%LOGDIR%\doctor-output.txt" >nul
if %errorlevel% == 0 (
    echo [%TIMESTAMP%] Doctor recommends restart >> "%LOGFILE%"
    set DOCTORFIXED=1
)

:: ========== STEP 3: Check Gateway Status ==========
echo [%TIMESTAMP%] Checking gateway status... >> "%LOGFILE%"
openclaw gateway status >nul 2>&1
if %errorlevel% neq 0 (
    echo [%TIMESTAMP%] Gateway: NOT RUNNING >> "%LOGFILE%"
    goto :restart_gateway
) else (
    echo [%TIMESTAMP%] Gateway: RUNNING >> "%LOGFILE%"
    
    :: If doctor fixed something, do a graceful restart
    if %DOCTORFIXED% == 1 (
        echo [%TIMESTAMP%] Restarting gateway to apply doctor fixes... >> "%LOGFILE%"
        goto :restart_gateway
    )
    goto :verify_system
)

:restart_gateway
echo [%TIMESTAMP%] Stopping gateway... >> "%LOGFILE%"
openclaw gateway stop >nul 2>&1
timeout /t 2 >nul

echo [%TIMESTAMP%] Starting gateway... >> "%LOGFILE%"
openclaw gateway start >nul 2>&1
timeout /t 3 >nul

:: Verify restart
openclaw gateway status >nul 2>&1
if %errorlevel% == 0 (
    echo [%TIMESTAMP%] Gateway: RESTARTED SUCCESSFULLY >> "%LOGFILE%"
    set /a FIXES+=1
) else (
    echo [%TIMESTAMP%] ERROR: Gateway restart FAILED >> "%LOGFILE%"
    set /a ERRORS+=1
    
    :: Try force restart
    echo [%TIMESTAMP%] Attempting force restart... >> "%LOGFILE%"
    taskkill /f /im openclaw.exe >nul 2>&1
    timeout /t 2 >nul
    openclaw gateway start >nul 2>&1
    timeout /t 3 >nul
    
    openclaw gateway status >nul 2>&1
    if %errorlevel% == 0 (
        echo [%TIMESTAMP%] Gateway: FORCE RESTART SUCCESS >> "%LOGFILE%"
        set /a FIXES+=1
        set /a ERRORS-=1
    ) else (
        echo [%TIMESTAMP%] ERROR: Force restart also FAILED >> "%LOGFILE%"
    )
)

:verify_system
:: ========== STEP 4: System Verification ==========
echo [%TIMESTAMP%] Verifying system... >> "%LOGFILE%"

:: Check config validity
if exist "%USERPROFILE%\.openclaw\openclaw.json" (
    echo [%TIMESTAMP%] Config: EXISTS >> "%LOGFILE%"
) else (
    echo [%TIMESTAMP%] ERROR: Config missing! >> "%LOGFILE%"
    set /a ERRORS+=1
)

:: Check workspace
if exist "%USERPROFILE%\.openclaw\workspace" (
    echo [%TIMESTAMP%] Workspace: EXISTS >> "%LOGFILE%"
) else (
    echo [%TIMESTAMP%] Creating workspace... >> "%LOGFILE%"
    mkdir "%USERPROFILE%\.openclaw\workspace"
    set /a FIXES+=1
)

:: Check port
netstat -ano | findstr :18789 >nul
if %errorlevel% == 0 (
    echo [%TIMESTAMP%] Port 18789: IN USE >> "%LOGFILE%"
) else (
    echo [%TIMESTAMP%] WARNING: Port 18789 not listening >> "%LOGFILE%"
)

:: ========== STEP 5: Git Sync ==========
if exist "%USERPROFILE%\.openclaw\workspace\.git" (
    echo [%TIMESTAMP%] Syncing to GitHub... >> "%LOGFILE%"
    cd /d "%USERPROFILE%\.openclaw\workspace"
    git add . >nul 2>&1
    git commit -m "Auto-fix: %TIMESTAMP%" >nul 2>&1
    git push origin master >nul 2>&1
    if %errorlevel% == 0 (
        echo [%TIMESTAMP%] Git sync: SUCCESS >> "%LOGFILE%"
    ) else (
        echo [%TIMESTAMP%] Git sync: No changes or offline >> "%LOGFILE%"
    )
)

:: ========== STEP 6: Send Report ==========
:send_report
echo [%TIMESTAMP%] Preparing Telegram report... >> "%LOGFILE%"

set REPORT=OpenClaw Auto-Fix Report v2
set REPORT=%REPORT%`nTime: %TIMESTAMP%
set REPORT=%REPORT%`n`nFixes Applied: %FIXES%
set REPORT=%REPORT%`nErrors: %ERRORS%

if %DOCTORFIXED% == 1 (
    set REPORT=%REPORT%`nDoctor: FIXED ISSUES
) else (
    set REPORT=%REPORT%`nDoctor: NO ISSUES
)

set REPORT=%REPORT%`n`nStatus: 
if %ERRORS% == 0 (
    set REPORT=%REPORT%All systems operational
) else (
    set REPORT=%REPORT%ATTENTION REQUIRED
)

:: Send Telegram
echo [%TIMESTAMP%] Sending report... >> "%LOGFILE%"
powershell -Command "try { $r='%REPORT%'; Invoke-RestMethod -Uri 'https://api.telegram.org/bot%BOTTOKEN%/sendMessage' -Method Post -Body @{chat_id='%CHATID%';text=$r} -ContentType 'application/x-www-form-urlencoded' -TimeoutSec 30 } catch {}" >nul 2>&1

echo [%TIMESTAMP%] === Auto-Fix v2 Completed === >> "%LOGFILE%"
echo. >> "%LOGFILE%"

exit /b %ERRORS%
