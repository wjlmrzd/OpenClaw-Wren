$jobs = Get-Content "D:\OpenClaw\.openclaw\workspace\cron\jobs.json" -Raw | ConvertFrom-Json
$i = 0
foreach ($job in $jobs.jobs) {
    $i++
    $model = $job.payload.model
    $cron = $job.schedule.expr
    $enabled = $job.enabled
    $jid = $job.id
    $jname = $job.name
    $shortId = if ($jid.Length -ge 8) { $jid.Substring(0,8) } else { $jid }
    Write-Host "$i | $shortId | $jname | Enabled=$enabled | Model=$model | Cron=$cron"
}
