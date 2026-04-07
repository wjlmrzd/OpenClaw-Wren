Get-ChildItem 'D:\OpenClaw\.openclaw\workspace\memory\2026-04-0*.md' | Sort-Object LastWriteTime -Descending | Select-Object -First 3 | ForEach-Object {
    $f = $_
    Write-Host "=== $($f.Name) ==="
    Get-Content $f.FullName | Select-Object -Last 30
    Write-Host ""
}
