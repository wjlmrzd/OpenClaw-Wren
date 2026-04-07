# 清理临时文件以释放 C 盘空间
$total = 0

$paths = @(
    "C:\Windows\Temp\*",
    "C:\Windows\Prefetch\*",
    "$env:TEMP\*",
    "C:\Users\Administrator\AppData\Local\Temp\*"
)

foreach ($p in $paths) {
    try {
        $items = Get-ChildItem $p -ErrorAction SilentlyContinue
        $size = ($items | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        if ($size -eq $null) { $size = 0 }
        $total += $size
        Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "[OK] Cleaned $p ($([math]::Round($size/1MB, 1)) MB)"
    } catch {
        Write-Host "[SKIP] $p - $($_.Exception.Message)"
    }
}

# 清理 npm 缓存（如果占用空间大）
$npmCache = "D:\OpenClaw\.npm-cache"
if (Test-Path $npmCache) {
    $npmSize = (Get-ChildItem $npmCache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Remove-Item "$npmCache\_cacache" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Cleaned npm cache ($([math]::Round($npmSize/1MB, 1)) MB)"
    $total += $npmSize
}

# 清理 openclaw npm cache
$ocCache = "C:\Users\Administrator\AppData\Local\npm-cache"
if (Test-Path $ocCache) {
    $ocSize = (Get-ChildItem $ocCache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Remove-Item $ocCache -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Cleaned openclaw npm cache ($([math]::Round($ocSize/1MB, 1)) MB)"
    $total += $ocSize
}

Write-Host ""
Write-Host "Total cleaned: $([math]::Round($total/1GB, 2)) GB"

# 检查 C 盘剩余空间
$disk = Get-PSDrive C
Write-Host "C: drive free space: $([math]::Round($disk.Free/1GB, 1)) GB"
