# 清理临时文件和缓存
$cleaned = 0

# 1. 清理 Windows 临时文件
$tempPaths = @(
    "$env:TEMP\*",
    "$env:TMP\*",
    "C:\Windows\Temp\*"
)
foreach ($path in $tempPaths) {
    try {
        $files = Get-Item -Path $path -Force -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            try {
                $cleaned += $file.Length
                Remove-Item -Path $file.FullName -Force -Recurse -ErrorAction SilentlyContinue
            } catch {}
        }
    } catch {}
}

# 2. 清理 .cache 文件夹中的旧文件
$cachePath = "C:\Users\Administrator\.cache"
if (Test-Path $cachePath) {
    try {
        $oldFiles = Get-ChildItem -Path $cachePath -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.LastAccessTime -lt (Get-Date).AddDays(-30) }
        foreach ($file in $oldFiles) {
            try {
                $cleaned += $file.Length
                Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
            } catch {}
        }
    } catch {}
}

Write-Output "清理完成，释放空间：$([math]::Round($cleaned / 1MB, 1)) MB"
