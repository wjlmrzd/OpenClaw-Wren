# Restore cron-list.json from cron-jobs.json
$jobsFile = "D:\OpenClaw\.openclaw\workspace\memory\cron-jobs.json"
$listFile = "D:\OpenClaw\.openclaw\workspace\memory\cron-list.json"

# Read jobs.json as UTF-8 (has BOM)
$utf8 = New-Object System.Text.UTF8Encoding $False
$jobsBytes = [System.IO.File]::ReadAllBytes($jobsFile)
$jobsText = $utf8.GetString($jobsBytes)

# Parse JSON
$data = $jobsText | ConvertFrom-Json
$jobs = $data.jobs
Write-Host "Jobs count: $($jobs.Count)"

# Apply fixes
$fixes = @(
    @{id="92af6946-b23b-4534-a6b8-5877cfa36f12"; timeout=300},
    @{id="3a1df011-613d-4528-a274-530cfd84f4fb"; timeout=300},
    @{id="58540a34-62ab-46a7-a713-cac112e5cd48"; timeout=180},
    @{id="0e63f087-5446-4033-b826-19dafe65673b"; timeout=600}
)

$changed = 0
foreach ($f in $fixes) {
    $job = $jobs | Where-Object { $_.id -eq $f.id }
    if ($job) {
        $old = $job.payload.timeoutSeconds
        $job.payload.timeoutSeconds = $f.timeout
        Write-Host "OK $($job.name): ${old}s -> $($f.timeout)s"
        $changed++
    }
}

# Fix scheduler delivery
$scheduler = $jobs | Where-Object { $_.id -eq "b6bc413c-0228-48c8-b42c-0af833216d2c" }
if ($scheduler) {
    $scheduler.delivery = @{mode="announce"; channel="last"}
    if ($scheduler.payload.timeoutSeconds -lt 600) {
        $old = $scheduler.payload.timeoutSeconds
        $scheduler.payload.timeoutSeconds = 600
        Write-Host "OK $($scheduler.name): ${old}s -> 600s"
        $changed++
    }
    Write-Host "OK $($scheduler.name): added delivery"
    $changed++
}

Write-Host "Total: $changed changes"

# Update state - reset consecutiveErrors
foreach ($job in $jobs) {
    if ($job.state) {
        $job.state.consecutiveErrors = 0
        $job.state.lastStatus = "ok"
        $job.state.PSObject.Properties.Remove("lastError")
    }
}

# Convert to JSON
$outJson = $data | ConvertTo-Json -Depth 20

# Write as UTF-16LE with BOM
$unicode = [System.Text.Encoding]::Unicode
$bom = $unicode.GetPreamble()
$bytes = $unicode.GetBytes($outJson)
$all = $bom + $bytes
[System.IO.File]::WriteAllBytes($listFile, $all)
Write-Host "Saved $listFile (UTF-16LE, $($all.Length) bytes)"

# Also update jobs.json
$outJson8 = $data | ConvertTo-Json -Depth 20
$utf8Bytes = $utf8.GetBytes($outJson8)
$all8 = (New-Object System.Text.UTF8Encoding $True).GetPreamble() + $utf8Bytes
[System.IO.File]::WriteAllBytes($jobsFile, $all8)
Write-Host "Updated $jobsFile (UTF-8 with BOM, $($all8.Length) bytes)"
