# 扫描用户目录和常见大文件位置
$paths = @(
    "C:\Users\Administrator",
    "C:\Users\Public",
    "C:\ProgramData",
    "C:\temp",
    "C:\tmp",
    "C:\OpenClaw"
)

foreach ($path in $paths) {
    if (Test-Path $path) {
        $size = (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        $sizeGB = [math]::Round($size / 1GB, 2)
        Write-Output "$path : $sizeGB GB"
    }
}
