$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$os = Get-CimInstance Win32_OperatingSystem
$memUsed = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)
$memTotal = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$memPct = [math]::Round($memUsed / $memTotal * 100, 1)

Write-Host "Memory: $memUsed GB / $memTotal GB ($memPct%)"
Get-PSDrive C, D | ForEach-Object {
    $free = [math]::Round($_.Free / 1GB, 1)
    $total = [math]::Round(($_.Free + $_.Used) / 1GB, 1)
    $pct = [math]::Round(($_.Used / ($_.Free + $_.Used)) * 100, 1)
    Write-Host "Disk $($_.Name): $free GB free / $total GB total ($pct%)"
}

Write-Host "--- Cron Failed Runs ---"
try {
    $runs = openclaw cron runs 2>$null | ConvertFrom-Json
    if ($runs) {
        $failed = $runs | Where-Object { $_.status -eq 'error' } | Select-Object -First 10
        Write-Host ("Failed count: " + $failed.Count)
        $failed | ForEach-Object {
            Write-Host ("  JobId: " + $_.jobId + " | Status: " + $_.status + " | Finished: " + $_.finishedAt)
        }
    } else {
        Write-Host "No runs data"
    }
} catch {
    Write-Host "Cron runs error: $_"
}
