# check-disk.ps1 - Disk space check (UTF-8 with BOM)
# Outputs disk usage for C: and D: drives

$ErrorActionPreference = "SilentlyContinue"

# C drive
try {
    $c = Get-PSDrive C
    $cTotal = [math]::Round(($c.Used + $c.Free) / 1GB, 2)
    $cUsed = [math]::Round($c.Used / 1GB, 2)
    $cFree = [math]::Round($c.Free / 1GB, 2)
    $cPct = [math]::Round(($c.Used / ($c.Used + $c.Free)) * 100, 1)
    Write-Output "C: Total=${cTotal}GB Used=${cUsed}GB Free=${cFree}GB ($cPct%)"
} catch {
    Write-Output "C: ERROR - $_"
}

# D drive
try {
    $d = Get-PSDrive D
    $dTotal = [math]::Round(($d.Used + $d.Free) / 1GB, 2)
    $dUsed = [math]::Round($d.Used / 1GB, 2)
    $dFree = [math]::Round($d.Free / 1GB, 2)
    $dPct = [math]::Round(($d.Used / ($d.Used + $d.Free)) * 100, 1)
    Write-Output "D: Total=${dTotal}GB Used=${dUsed}GB Free=${dFree}GB ($dPct%)"
} catch {
    Write-Output "D: ERROR - $_"
}
