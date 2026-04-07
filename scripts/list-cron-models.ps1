$jobs = Get-Content "$env:OPENCLAW_HOME\.openclaw\cron\jobs.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$jobs | ForEach-Object {
    $item = $_
    $id = if ($item.id) { $item.id } else { 'N/A' }
    $name = if ($item.name) { $item.name } elseif ($item.job.name) { $item.job.name } else { 'N/A' }
    $model = if ($item.payload.model) { $item.payload.model } elseif ($item.job.payload.model) { $item.job.payload.model } else { 'N/A' }
    Write-Output ("{0,-25} | {1,-50} | {2}" -f $name, $model, $id)
}
