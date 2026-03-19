@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set LOGDIR=%USERPROFILE%\.openclaw\logs
set LOGFILE=%LOGDIR%\health-check.log
set REPORTFILE=%LOGDIR%\health-check-report.txt
set BOTTOKEN=8329757047:AAFxkpIJqkm-8HT1ZFz005tjFDeRRRIisH0
set CHATID=8542040756

if not exist "%LOGDIR%" mkdir "%LOGDIR%"

for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value ^| find "="') do set dt=%%a
set TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2% %dt:~8,2%:%dt:~10,2%

echo [%TIMESTAMP%] === Health Check Started === >> "%LOGFILE%"

set REPORT=OpenClaw Health Check Report
set REPORT=%REPORT%`nTime: %TIMESTAMP%
set REPORT=%REPORT%`n

:: Check Gateway Status
echo [%TIMESTAMP%] Checking gateway... >> "%LOGFILE%"
openclaw gateway status > "%TEMP%\gateway_status.txt" 2>&1
set /p GATEWAY_STATUS=<"%TEMP%\gateway_status.txt"
del "%TEMP%\gateway_status.txt"

echo %GATEWAY_STATUS% | findstr /i "running" >nul
if %errorlevel% == 0 (
    echo [%TIMESTAMP%] Gateway: RUNNING >> "%LOGFILE%"
    set REPORT=%REPORT%Gateway: RUNNING`n
) else (
    echo [%TIMESTAMP%] Gateway: NOT RUNNING, restarting... >> "%LOGFILE%"
    openclaw gateway start >nul 2>&1
    timeout /t 3 /nobreak >nul
    set REPORT=%REPORT%Gateway: RESTARTED`n
)

:: Check Disk Space
for /f "usebackq tokens=3" %%a in (`wmic logicaldisk where "DeviceID='C:'" get FreeSpace ^| findstr /v "FreeSpace"`) do set FREE=%%a
for /f "usebackq tokens=3" %%a in (`wmic logicaldisk where "DeviceID='C:'" get Size ^| findstr /v "Size"`) do set TOTAL=%%a
set /a FREEGB=%FREE:~0,-10%
set /a TOTALGB=%TOTAL:~0,-10%
set /a PERCENT=(%FREEGB%*100)/%TOTALGB%
echo [%TIMESTAMP%] Disk: %FREEGB%GB free of %TOTALGB%GB >> "%LOGFILE%"
set REPORT=%REPORT%Disk: %FREEGB%GB / %TOTALGB%GB (%PERCENT%%% free)`n

:: Check Memory
for /f "skip=1" %%a in ('wmic os get TotalVisibleMemorySize') do set TOTALMEM=%%a
for /f "skip=1" %%a in ('wmic os get FreePhysicalMemory') do set FREEMEM=%%a
set /a TOTALMEMMB=%TOTALMEM:~0,-4%
set /a FREEMEMMB=%FREEMEM:~0,-4%
set /a USEDMEMMB=%TOTALMEMMB% - %FREEMEMMB%
set /a MEMPERCENT=(%USEDMEMMB%*100)/%TOTALMEMMB%
echo [%TIMESTAMP%] Memory: %USEDMEMMB%MB used of %TOTALMEMMB%MB >> "%LOGFILE%"
set REPORT=%REPORT%Memory: %USEDMEMMB%MB / %TOTALMEMMB%MB (%MEMPERCENT%%% used)`n`n

:: Security Audit
echo [%TIMESTAMP%] Running security audit... >> "%LOGFILE%"
set REPORT=%REPORT%Security Audit:`n

if exist "%USERPROFILE%\.openclaw\openclaw.json" (
    echo [%TIMESTAMP%] Config: EXISTS >> "%LOGFILE%"
    set REPORT=%REPORT%- Config: EXISTS`n
) else (
    echo [%TIMESTAMP%] Config: NOT FOUND >> "%LOGFILE%"
    set REPORT=%REPORT%- Config: NOT FOUND`n
)

if exist "%USERPROFILE%\.openclaw\workspace" (
    set REPORT=%REPORT%- Workspace: EXISTS`n
) else (
    set REPORT=%REPORT%- Workspace: MISSING`n
)

:: Send Telegram Report
echo [%TIMESTAMP%] Sending Telegram report... >> "%LOGFILE%"

set JSON={"chat_id":"%CHATID%","text":"%REPORT%","parse_mode":"Markdown"}
powershell -Command "Invoke-RestMethod -Uri 'https://api.telegram.org/bot%BOTTOKEN%/sendMessage' -Method Post -ContentType 'application/json' -Body '%JSON%'" >nul 2>&1

echo [%TIMESTAMP%] === Health Check Completed === >> "%LOGFILE%"
echo. >> "%LOGFILE%"

exit /b 0
