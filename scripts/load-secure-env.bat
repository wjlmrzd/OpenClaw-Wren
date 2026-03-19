@echo off
:: Load secure configuration from encrypted storage
:: Sets environment variables for use in other scripts

set SECURESCRIPT=D:\OpenClaw\.openclaw\workspace\scripts\secure-storage.ps1

if not exist "%SECURESCRIPT%" (
    echo ERROR: Secure storage script not found
    exit /b 1
)

:: Generate temp file with SET commands
powershell -ExecutionPolicy Bypass -File "%SECURESCRIPT%" -Load > "%TEMP%\secure-env.bat" 2>nul

if %errorlevel% neq 0 (
    echo ERROR: Failed to load secure configuration
    exit /b 1
)

:: Execute SET commands
call "%TEMP%\secure-env.bat"

:: Clean up
del "%TEMP%\secure-env.bat"

exit /b 0
