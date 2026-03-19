@echo off
:: Load environment variables from .env file
:: Usage: call load-env.bat

set ENVFILE=%USERPROFILE%\.openclaw\workspace\.env

if not exist "%ENVFILE%" (
    echo ERROR: .env file not found at %ENVFILE%
    exit /b 1
)

for /f "usebackq tokens=*" %%a in ("%ENVFILE%") do (
    set line=%%a
    if not "!line:~0,1!"=="#" (
        if not "!line!"=="" (
            for /f "tokens=1,* delims==" %%b in ("%%a") do (
                set %%b=%%c
            )
        )
    )
)
