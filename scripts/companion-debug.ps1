$ErrorActionPreference = 'Continue'
$h = (Get-Date).Hour
Write-Host "Hour=$h"
$r = Get-Random -Maximum 100
Write-Host "Rand=$r"
$sf = 'D:\OpenClaw\.openclaw\workspace\memory\companion\state.json'
$st = Get-Content $sf -Raw -Encoding UTF8 | ConvertFrom-Json
Write-Host "st.lm=$($st.lm)"
if ($st.lm) {
    $s = ((Get-Date).ToUniversalTime().Ticks - $st.lm) / 36000000
    Write-Host "HoursSince=$s"
} else {
    Write-Host 'lm is null'
}
