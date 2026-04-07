$data = Get-Content 'D:\OpenClaw\.openclaw\workspace\cron\jobs.json' -Raw | ConvertFrom-Json
$target = $data.jobs | Where-Object { $_.name -like '*错误恢复*' }
if ($target) {
    $target | ConvertTo-Json -Depth 10
} else {
    Write-Host "No job found with name containing '错误恢复'"
    # Also check for similar names
    $data.jobs | ForEach-Object { 
        if ($_.name -match '恢复|急救|healer') {
            Write-Host "Found: $($_.name) - ID: $($_.id)"
        }
    }
}
