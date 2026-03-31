$proc = Get-Process -Name 'node' -ErrorAction SilentlyContinue
if ($proc) {
    Write-Host "Node processes: $($proc.Count)"
    foreach ($p in $proc) {
        Write-Host "  PID: $($p.Id) | Mem: $([math]::Round($p.WorkingSet64/1MB,1)) MB | CPU: $($p.CPU)"
    }
} else {
    Write-Host "No node process found"
}
