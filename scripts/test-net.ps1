try {
    $r = Invoke-WebRequest -Uri 'https://api.github.com/repos/liamcain/obsidian-calendar-plugin/releases/latest' -TimeoutSec 10
    Write-Host "Calendar plugin: OK $($r.StatusCode)"
} catch {
    Write-Host "Calendar plugin: FAIL $($_.Exception.Message)"
}

try {
    $r2 = Invoke-WebRequest -Uri 'https://api.github.com/repos/deu1/execute/obsidian-rss/releases/latest' -TimeoutSec 10
    Write-Host "RSS plugin: OK $($r2.StatusCode)"
} catch {
    Write-Host "RSS plugin: FAIL $($_.Exception.Message)"
}
