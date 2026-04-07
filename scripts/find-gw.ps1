$nodes = Get-Process node -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -like '*openclaw*' -or $_.CommandLine -like '*openclaw*' }
if (-not $nodes) { $nodes = Get-Process node -ErrorAction SilentlyContinue }
if ($nodes) {
    foreach ($n in $nodes) {
        $mem = [math]::Round($n.WorkingSet64/1MB, 0)
        $start = $n.StartTime.ToString("yyyy-MM-dd HH:mm:ss")
        $uptime = ((Get-Date) - $n.StartTime).ToString("dd\.hh\:mm\:ss")
        Write-Output "NODE|$($n.Id)|$mem|$start|$uptime"
    }
} else {
    Write-Output "NODE|NONE"
}
