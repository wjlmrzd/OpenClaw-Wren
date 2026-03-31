try {
    $content = Get-Content "D:\OpenClaw\.openclaw\cron\jobs.json" -Raw -Encoding UTF8
    $json = $content | ConvertFrom-Json
    Write-Host "JSON is valid. Job count: $($json.jobs.Count)"
    
    $enabled = ($json.jobs | Where-Object { $_.enabled }).Count
    $disabled = ($json.jobs | Where-Object { -not $_.enabled }).Count
    Write-Host "Enabled: $enabled, Disabled: $disabled"
} catch {
    Write-Host "JSON ERROR: $_"
    Write-Host "Error at: $($_.ScriptStackTrace)"
}
