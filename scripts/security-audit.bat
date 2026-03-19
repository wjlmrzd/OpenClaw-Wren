@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Security Audit Script with Telegram Report
:: Run manually or via scheduled task

set SCRIPTDIR=%~dp0
set LOGDIR=C:\Users\Administrator\.openclaw\logs
set LOGFILE=%LOGDIR%\security-audit.log

:: Load secure environment
call "%SCRIPTDIR%load-secure-env.bat"
if %errorlevel% neq 0 (
    echo [%date% %time%] ERROR: Failed to load secure env >> "%LOGFILE%"
    exit /b 1
)

if not exist "%LOGDIR%" mkdir "%LOGDIR%"

for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value ^| find "="') do set dt=%%a
set TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2% %dt:~8,2%:%dt:~10,2%

echo [%TIMESTAMP%] === Security Audit Started === >> "%LOGFILE%"

set ISSUES=0
set WARNINGS=0

:: Build report
set REPORT=Security Audit Report
set REPORT=%REPORT%`nTime: %TIMESTAMP%
set REPORT=%REPORT%`n

:: ========== 1. Gateway Security ==========
echo [%TIMESTAMP%] Checking gateway security... >> "%LOGFILE%"
set REPORT=%REPORT%Gateway Security:

openclaw gateway status >nul 2>&1
if %errorlevel% == 0 (
    set REPORT=%REPORT%`n- Status: RUNNING
    
    :: Check bind mode
    findstr /i "\"bind\":\"loopback\"" "%USERPROFILE%\.openclaw\openclaw.json" >nul
    if %errorlevel% == 0 (
        set REPORT=%REPORT%`n- Bind mode: loopback (secure)
    ) else (
        set REPORT=%REPORT%`n- Bind mode: WARNING - not loopback
        set /a WARNINGS+=1
    )
    
    :: Check auth
    findstr /i "\"auth\"" "%USERPROFILE%\.openclaw\openclaw.json" >nul
    if %errorlevel% == 0 (
        set REPORT=%REPORT%`n- Auth: configured
    ) else (
        set REPORT=%REPORT%`n- Auth: WARNING - not configured
        set /a WARNINGS+=1
    )
) else (
    set REPORT=%REPORT%`n- Status: NOT RUNNING
    set /a ISSUES+=1
)
set REPORT=%REPORT%`n

:: ========== 2. File Permissions ==========
echo [%TIMESTAMP%] Checking file permissions... >> "%LOGFILE%"
set REPORT=%REPORT%File Security:

if exist "%USERPROFILE%\.openclaw\openclaw.json" (
    set REPORT=%REPORT%`n- Config file: exists
    
    :: Check for plaintext tokens (simple check)
    findstr /i "gho_\|bot[0-9]\+:\|sk-\|AKIA" "%USERPROFILE%\.openclaw\openclaw.json" >nul
    if %errorlevel% == 0 (
        set REPORT=%REPORT%`n- WARNING: Possible plaintext tokens in config
        set /a WARNINGS+=1
    ) else (
        set REPORT=%REPORT%`n- No obvious plaintext tokens
    )
) else (
    set REPORT=%REPORT%`n- Config file: MISSING
    set /a ISSUES+=1
)

:: Check secure storage
if exist "%USERPROFILE%\.openclaw\secure\tokens.enc" (
    set REPORT=%REPORT%`n- Secure storage: exists (encrypted)
) else (
    set REPORT=%REPORT%`n- Secure storage: NOT INITIALIZED
    set /a WARNINGS+=1
)
set REPORT=%REPORT%`n

:: ========== 3. System Security ==========
echo [%TIMESTAMP%] Checking system security... >> "%LOGFILE%"
set REPORT=%REPORT%System Security:

:: Check port exposure
netstat -an | findstr "0.0.0.0:18789" >nul
if %errorlevel% == 0 (
    set REPORT=%REPORT%`n- Port 18789: EXPOSED to all interfaces
    set /a WARNINGS+=1
) else (
    netstat -an | findstr "127.0.0.1:18789" >nul
    if %errorlevel% == 0 (
        set REPORT=%REPORT%`n- Port 18789: localhost only (secure)
    ) else (
        set REPORT=%REPORT%`n- Port 18789: not listening
    )
)

:: Check firewall status (simplified)
netsh advfirewall show currentprofile | findstr "ON" >nul
if %errorlevel% == 0 (
    set REPORT=%REPORT%`n- Firewall: ON
) else (
    set REPORT=%REPORT%`n- Firewall: OFF
    set /a WARNINGS+=1
)
set REPORT=%REPORT%`n

:: ========== 4. Git Security ==========
echo [%TIMESTAMP%] Checking git security... >> "%LOGFILE%"
set REPORT=%REPORT%Git Security:

if exist "%USERPROFILE%\.openclaw\workspace\.git" (
    set REPORT=%REPORT%`n- Repository: initialized
    
    :: Check if .env is ignored
    findstr /i "\.env" "%USERPROFILE%\.openclaw\workspace\.gitignore" >nul
    if %errorlevel% == 0 (
        set REPORT=%REPORT%`n- .env ignored: YES
    ) else (
        set REPORT=%REPORT%`n- .env ignored: NO
        set /a WARNINGS+=1
    )
    
    :: Check for secure directory
    findstr /i "secure/" "%USERPROFILE%\.openclaw\workspace\.gitignore" >nul
    if %errorlevel% == 0 (
        set REPORT=%REPORT%`n- Secure dir ignored: YES
    ) else (
        set REPORT=%REPORT%`n- Secure dir ignored: NO
        set /a WARNINGS+=1
    )
) else (
    set REPORT=%REPORT%`n- Repository: not initialized
)
set REPORT=%REPORT%`n

:: ========== 5. Summary ==========
echo [%TIMESTAMP%] Audit complete >> "%LOGFILE%"
set REPORT=%REPORT%---
set REPORT=%REPORT%`nSummary:
set REPORT=%REPORT%`n- Issues: %ISSUES%
set REPORT=%REPORT%`n- Warnings: %WARNINGS%

if %ISSUES% == 0 if %WARNINGS% == 0 (
    set REPORT=%REPORT%`n- Status: All checks passed
) else (
    if %ISSUES% gtr 0 (
        set REPORT=%REPORT%`n- Status: ISSUES FOUND
    ) else (
        set REPORT=%REPORT%`n- Status: WARNINGS
    )
)

set REPORT=%REPORT%`n`nLog: %LOGFILE%

:: Send Telegram Report
echo [%TIMESTAMP%] Sending Telegram report... >> "%LOGFILE%"
powershell -Command "try { Invoke-RestMethod -Uri 'https://api.telegram.org/bot%TELEGRAM_BOT_TOKEN%/sendMessage' -Method Post -Body @{chat_id='%TELEGRAM_CHAT_ID%';text='%REPORT%'} -ContentType 'application/x-www-form-urlencoded' -TimeoutSec 30 } catch {}" >nul 2>&1

echo [%TIMESTAMP%] === Security Audit Completed === >> "%LOGFILE%"
echo. >> "%LOGFILE%"

exit /b %ISSUES%
