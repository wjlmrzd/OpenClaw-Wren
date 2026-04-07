# Restore and fix cron files
$jobsFile = "D:\OpenClaw\.openclaw\workspace\memory\cron-jobs.json"
$listFile = "D:\OpenClaw\.openclaw\workspace\memory\cron-list.json"

# Read from git-restore UTF-8
$jobsText = Get-Content $jobsFile -Raw -Encoding UTF8
$data = $jobsText | ConvertFrom-Json
$jobs = $data.jobs
Write-Host "Jobs: $($jobs.Count)"

$changed = 0

# Fix timeouts
$fixes = @(
    @{id="92af6946-b23b-4534-a6b8-5877cfa36f12"; timeout=300},
    @{id="3a1df011-613d-4528-a274-530cfd84f4fb"; timeout=300},
    @{id="58540a34-62ab-46a7-a713-cac112e5cd48"; timeout=180},
    @{id="0e63f087-5446-4033-b826-19dafe65673b"; timeout=600}
)

foreach ($f in $fixes) {
    $job = $jobs | Where-Object { $_.id -eq $f.id }
    if ($job) {
        $old = $job.payload.timeoutSeconds
        $job.payload.timeoutSeconds = $f.timeout
        Write-Host "OK $($job.name): ${old}s -> $($f.timeout)s"
        $changed++
    }
}

# Fix scheduler optimizer delivery
$sched = $jobs | Where-Object { $_.id -eq "b6bc413c-0228-48c8-b42c-0af833216d2c" }
if ($sched) {
    $sched.delivery = @{mode="announce"; channel="last"}
    if ($sched.payload.timeoutSeconds -lt 600) {
        $old = $sched.payload.timeoutSeconds
        $sched.payload.timeoutSeconds = 600
        Write-Host "OK $($sched.name): ${old}s -> 600s"
        $changed++
    }
    Write-Host "OK $($sched.name): added delivery {mode:announce, channel:last}"
    $changed++
}

# Reset error counters
foreach ($j in $jobs) {
    if ($j.state) {
        $j.state.consecutiveErrors = 0
        $j.state.lastStatus = "ok"
        $j.state.PSObject.Properties.Remove("lastError")
        $j.state.PSObject.Properties.Remove("runningAtMs")
    }
}

Write-Host "Total changes: $changed"

# Save jobs.json as UTF-8 with BOM
$json8 = $data | ConvertTo-Json -Depth 20
$utf8Bom = New-Object System.Text.UTF8Encoding $True
$utf8Bytes = $utf8Bom.GetBytes($json8)
[System.IO.File]::WriteAllBytes($jobsFile, $utf8Bytes)
Write-Host "Saved $jobsFile ($($utf8Bytes.Length) bytes)"

# Save list.json as UTF-16LE with BOM
$jsonOut = $data | ConvertTo-Json -Depth 20
$uni = [System.Text.Encoding]::Unicode
$bomBytes = $uni.GetPreamble()
$dataBytes = $uni.GetBytes($jsonOut)
$allBytes = $bomBytes + $dataBytes
[System.IO.File]::WriteAllBytes($listFile, $allBytes)
Write-Host "Saved $listFile ($($allBytes.Length) bytes, UTF-16LE)"
