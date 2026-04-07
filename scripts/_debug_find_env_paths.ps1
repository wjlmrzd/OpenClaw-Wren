# _debug_find_env_paths.ps1
Get-ChildItem 'D:\OpenClaw\.openclaw\workspace\scripts\' -File -Filter *.ps1 | ForEach-Object {
    $lines = Get-Content $_.FullName
    $linenum = 0
    foreach ($line in $lines) {
        $linenum++
        if ($line -match 'workspace.*\.env|\.env.*workspace|OPENCLAW_HOME.*workspace') {
            Write-Output "FILE: $($_.Name) LINE $linenum"
            Write-Output "  $_"
        }
    }
}
