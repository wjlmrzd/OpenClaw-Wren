$files = @(
    "D:\OpenClaw\.openclaw\workspace\memory\cron-jobs.json",
    "D:\OpenClaw\.openclaw\workspace\cron\jobs.json",
    "D:\OpenClaw\.openclaw\workspace\memory\cron-list.json",
    "D:\OpenClaw\.openclaw\workspace\memory\test-git.json"
)
foreach ($f in $files) {
    try {
        $data = Get-Content $f -Raw -Encoding UTF8 | ConvertFrom-Json
        $count = $data.jobs.Count
        $size = (Get-Item $f).Length
        $hasBom = (Get-Content $f -TotalCount 1 -Encoding Byte)[0..2] -join ' ' -eq '239 187 191'
        Write-Host "$($f.Split('\')[-1]): OK $count jobs, $size bytes, BOM=$hasBom"
    } catch {
        Write-Host "$($f.Split('\')[-1]): FAILED $($_.Exception.Message)"
    }
}
