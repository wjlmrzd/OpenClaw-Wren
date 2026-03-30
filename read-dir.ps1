Get-ChildItem 'D:\OpenClaw\.openclaw\workspace\CadAttrBlockConverter' -Directory | ForEach-Object {
    Write-Host "=== DIRECTORY ==="
    Write-Host "Name: $($_.Name)"
    Write-Host "FullName: $($_.FullName)"
    Write-Host "---"
}
