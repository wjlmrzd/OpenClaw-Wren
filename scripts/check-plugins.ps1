$log = Get-Content 'C:\tmp\clawdbot\clawdbot-2026-04-02.log' -Tail 200
$errors = $log | Select-String 'registerContextEngine'
if ($errors) {
    Write-Host "=== LAST 5 registerContextEngine ERRORS ==="
    $errors | Select-Object -Last 5 | ForEach-Object { $_.Line.Substring(0, [Math]::Min(300, $_.Line.Length)) }
} else {
    Write-Host "NO registerContextEngine errors found in last 200 lines"
}
Write-Host ""
Write-Host "=== RECENT plugin lines ==="
$log | Select-String 'plugins' | Select-Object -Last 10 | ForEach-Object { $_.Line.Substring(0, [Math]::Min(200, $_.Line.Length)) }
