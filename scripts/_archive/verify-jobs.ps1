$bytes = [System.IO.File]::ReadAllBytes("D:\OpenClaw\.openclaw\workspace\cron\jobs.json")
$start = 0
if ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $start = 3
}
$text = [System.Text.Encoding]::UTF8.GetString($bytes, $start, $bytes.Length - $start)
try {
    $data = $text | ConvertFrom-Json
    Write-Host "JSON OK: $($data.jobs.Count) jobs"
    $data.jobs | ForEach-Object { Write-Host "  $($_.name)" }
} catch {
    Write-Host "JSON Error: $($_.Exception.Message)"
}
