$jobs = Get-Content "D:\OpenClaw\.openclaw\cron\jobs.json" -Raw | ConvertFrom-Json
$jobs.jobs | Where-Object { $_.enabled -and $_.delivery.mode -ne "none" } | ForEach-Object {
  $id = $_.id.Substring(0,8)
  $name = $_.name
  $mode = $_.delivery.mode
  "$id | $name | $mode"
}
