@echo off
chcp 65001 >nul
:: Manual Git Push Script
:: Usage: manual-push.bat "commit message"

cd /d D:\OpenClaw\.openclaw\workspace

if "%~1"=="" (
    echo Usage: manual-push.bat "your commit message"
    exit /b 1
)

echo Adding files...
git add .

echo Committing: %~1
git commit -m "%~1"

echo Pushing to GitHub...
git push origin master

if %errorlevel% == 0 (
    echo Push successful!
) else (
    echo Push failed or no changes to push
)
