Write-Output "=== .cache 文件夹内容 ==="
Get-ChildItem -Path "C:\Users\Administrator\.cache" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $size = (Get-ChildItem -Path $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
    if ($size -gt 0) {
        Write-Output "$($_.Name): $([math]::Round($size/1MB,1)) MB"
    }
}

Write-Output "`n=== WPSDrive 文件夹内容 ==="
Get-ChildItem -Path "C:\Users\Administrator\WPSDrive" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $size = (Get-ChildItem -Path $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
    if ($size -gt 0) {
        Write-Output "$($_.Name): $([math]::Round($size/1MB,1)) MB"
    }
}
