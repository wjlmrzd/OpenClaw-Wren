[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
Get-ChildItem 'E:\' -Directory -Force | ForEach-Object { $_ }
