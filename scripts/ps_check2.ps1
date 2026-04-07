# Check all node processes related to openclaw
Get-Process node -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -like '*openclaw*' -or $_.Path -like '*nodejs*'
} | ForEach-Object {
    $ws = [math]::Round($_.WorkingSet64 / 1MB, 1)
    $cpu = [math]::Round($_.TotalProcessorTime.TotalSeconds, 0)
    Write-Host "node  PID=$($_.Id)  Memory=${ws}MB  CPU=${cpu}s  Start=$($_.StartTime)"
    Write-Host "     Path: $($_.Path)"
}
Write-Host ""
Write-Host "Total node processes with openclaw path: $((Get-Process node -ErrorAction SilentlyContinue | Where-Object {$_.Path -like '*openclaw*'}).Count)"
