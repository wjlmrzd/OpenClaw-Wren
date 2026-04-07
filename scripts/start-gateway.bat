@echo off
chcp 65001 >nul 2>&1
title OpenClaw Gateway
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-gateway.ps1"