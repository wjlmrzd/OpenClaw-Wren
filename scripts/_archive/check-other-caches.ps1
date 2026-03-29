Write-Output "=== 其他缓存文件夹 ==="
$folders = @('.rustup', '.node-llama-cpp', '.trae-cn', '.claude', 'Downloads', 'Documents')
foreach ($folder in $folders) {
    $path = "C:\Users\Administrator\$folder"
    if (Test-Path $path) {
        $size = (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        if ($size -gt 50MB) {
            Write-Output "$folder : $([math]::Round($size/1MB,1)) MB"
        }
    }
}
