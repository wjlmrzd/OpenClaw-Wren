[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$out = @()
Get-ChildItem 'D:\' -Directory -Force | ForEach-Object { $out += $_.Name }
$out | Out-File -FilePath 'D:\OpenClaw\.openclaw\workspace\temp\d-listing.txt' -Encoding UTF8
Write-Output 'Done'
