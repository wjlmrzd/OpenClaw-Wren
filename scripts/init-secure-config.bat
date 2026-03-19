@echo off
:: Initialize secure configuration storage

set CONFIGDIR=%USERPROFILE%\.openclaw\secure
set CONFIGFILE=%CONFIGDIR%\tokens.dat

if not exist "%CONFIGDIR%" mkdir "%CONFIGDIR%"

:: Store tokens using PowerShell encryption
echo Storing tokens securely...

powershell -Command "$data=@{
    'TELEGRAM_BOT_TOKEN'='8329757047:AAFxkpIJqkm-8HT1ZFz005tjFDeRRRIisH0';
    'TELEGRAM_CHAT_ID'='8542040756';
    'BRAVE_SEARCH_API_KEY'='BSAD9CpbQ_U660f8h-uoXk2cJJ1gdbQ'
}; $json=$data|ConvertTo-Json; $bytes=[Text.Encoding]::UTF8.GetBytes($json); $enc=[Security.Cryptography.ProtectedData]::Protect($bytes,$null,'CurrentUser'); [IO.File]::WriteAllBytes('%CONFIGFILE%',$enc); Write-Host 'Tokens stored securely'"

echo Secure config initialized at: %CONFIGFILE%
