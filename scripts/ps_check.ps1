$nodes = Get-Process node -ErrorAction SilentlyContinue | Where-Object { $_.Path -like '*openclaw*' }
$nodes += Get-Process -Name 'openclaw*' -ErrorAction SilentlyContinue
$nodes = $nodes | Sort-Object Id -Unique

foreach ($n in $nodes) {
    $ws = [math]::Round($n.WorkingSet64 / 1MB, 1)
    $path = $n.Path
    if ($path -match 'node_modules[\\\/]openclaw') {
        $match = [regex]::Match($path, 'node_modules[\\\/]openclaw[^\\\/]*')
        $short = $match.Value
    } else {
        $short = $path
    }
    Write-Host "$($n.Name)  PID=$($n.Id)  Memory=${ws}MB  Start=$($n.StartTime)  $short"
}
