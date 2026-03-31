$content = Get-Content 'D:\OpenClaw\.openclaw\cron\jobs.json' -Raw -Encoding UTF8
$json = $content | ConvertFrom-Json
$changed = 0

$targetIds = @(
    '7eb7f35e-fe72-4a90-bfc6-ed59392b10f6',
    'f920c2a2-6afc-4fc8-84ad-01593d2d22d1',
    '16c5208a-e77c-4b6f-a8be-eb6e62807a07',
    'b8665efb-6e32-4a0b-b9ed-39ed69c69185',
    'ddd96cfb-f017-475e-8b2b-34c522b9ddae'
)

foreach ($job in $json.jobs) {
    foreach ($tid in $targetIds) {
        if ($job.id -eq $tid) {
            $oldVal = $job.enabled
            $job.enabled = $false
            $now = [int64](Get-Date -UFormat '%s') * 1000
            $job.updatedAtMs = $now
            if (-not $oldVal) {
                Write-Host "Disabled: $($job.id)"
                $changed++
            } else {
                Write-Host "Already disabled: $($job.id)"
            }
        }
    }
}

$json | ConvertTo-Json -Depth 20 | Set-Content 'D:\OpenClaw\.openclaw\cron\jobs.json' -Encoding UTF8
Write-Host "Changed: $changed jobs"
