# C 盘安全清理脚本
# 清理临时文件、更新缓存、回收站、浏览器缓存

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  C Drive Cleanup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. 清理当前用户临时文件
Write-Host "[1/5] Cleaning user temp files..." -ForegroundColor Yellow
$currentUserTemp = $env:TEMP
if (Test-Path $currentUserTemp) {
    Remove-Item $currentUserTemp\* -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Done: $currentUserTemp" -ForegroundColor Green
} else {
    Write-Host "  - Path not found" -ForegroundColor Gray
}

# 2. 清理 Windows 系统临时文件
Write-Host "[2/5] Cleaning system temp files..." -ForegroundColor Yellow
$systemTemp = "C:\Windows\Temp"
if (Test-Path $systemTemp) {
    Remove-Item $systemTemp\* -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Done: $systemTemp" -ForegroundColor Green
} else {
    Write-Host "  - Path not found" -ForegroundColor Gray
}

# 3. 清理 Windows Update 缓存
Write-Host "[3/5] Cleaning Windows Update cache..." -ForegroundColor Yellow
try {
    Write-Host "  Stopping Windows Update service..." -ForegroundColor Gray
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    
    $updateCache = "C:\Windows\SoftwareDistribution\Download"
    if (Test-Path $updateCache) {
        Remove-Item $updateCache\* -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  Done: $updateCache" -ForegroundColor Green
    }
    
    Write-Host "  Starting Windows Update service..." -ForegroundColor Gray
    Start-Service -Name wuauserv -ErrorAction SilentlyContinue
    Write-Host "  Service restarted" -ForegroundColor Green
} catch {
    Write-Host "  Warning: Error cleaning Update cache" -ForegroundColor Red
}

# 4. 清空回收站
Write-Host "[4/5] Clearing Recycle Bin..." -ForegroundColor Yellow
try {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Host "  Recycle Bin cleared" -ForegroundColor Green
} catch {
    Write-Host "  Warning: Error clearing Recycle Bin" -ForegroundColor Red
}

# 5. 清理浏览器缓存
Write-Host "[5/5] Cleaning browser cache..." -ForegroundColor Yellow
$username = $env:USERNAME

$chromeCache = "C:\Users\$username\AppData\Local\Google\Chrome\User Data\Default\Cache"
if (Test-Path $chromeCache) {
    Remove-Item $chromeCache\* -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Chrome cache cleared" -ForegroundColor Green
} else {
    Write-Host "  - Chrome cache not found" -ForegroundColor Gray
}

$edgeCache = "C:\Users\$username\AppData\Local\Microsoft\Edge\User Data\Default\Cache"
if (Test-Path $edgeCache) {
    Remove-Item $edgeCache\* -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Edge cache cleared" -ForegroundColor Green
} else {
    Write-Host "  - Edge cache not found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Cleanup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Checking disk space..." -ForegroundColor Yellow
$disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeSpace = $disk.FreeSpace
$totalSpace = $disk.Size
$freeGB = [math]::Round($freeSpace / 1GB, 2)
$totalGB = [math]::Round($totalSpace / 1GB, 2)

Write-Host ""
Write-Host "  C: Drive - Free: $freeGB GB of $totalGB GB" -ForegroundColor Cyan
Write-Host ""
