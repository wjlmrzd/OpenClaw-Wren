@echo off
chcp 65001 >nul
set LOGDIR=C:\Users\Administrator\.openclaw\logs
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

echo [%date% %time%] Health Check Started >> "%LOGDIR%\health-check.log"

:: Simple report
echo OpenClaw Health Check Report > "%LOGDIR%\report.txt"
echo Time: %date% %time% >> "%LOGDIR%\report.txt"
echo. >> "%LOGDIR%\report.txt"

:: Check gateway
openclaw gateway status >nul 2>&1
if %errorlevel% == 0 (
    echo Gateway: RUNNING >> "%LOGDIR%\report.txt"
) else (
    echo Gateway: NOT RUNNING, restarting... >> "%LOGDIR%\report.txt"
    openclaw gateway start >nul 2>&1
    timeout /t 3 >nul
    echo Gateway: RESTARTED >> "%LOGDIR%\report.txt"
)

:: Send to Telegram via PowerShell
powershell -Command "$r=Get-Content '%LOGDIR%\report.txt' -Raw; Invoke-RestMethod -Uri 'https://api.telegram.org/bot8329757047:AAFxkpIJqkm-8HT1ZFz005tjFDeRRRIisH0/sendMessage' -Method Post -Body @{chat_id='8542040756';text=$r} -ContentType 'application/x-www-form-urlencoded'" >nul 2>&1

echo [%date% %time%] Health Check Completed >> "%LOGDIR%\health-check.log"
