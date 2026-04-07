# PowerShell handles UTF-16LE correctly
$file = "D:\OpenClaw\.openclaw\workspace\memory\cron-list.json"
$json = Get-Content $file -Encoding BigEndianUnicode -Raw
$data = $json | ConvertFrom-Json

$fixes = @(
    @{id="92af6946-b23b-4534-a6b8-5877cfa36f12"; timeout=300},
    @{id="3a1df011-613d-4528-a274-530cfd84f4fb"; timeout=300},
    @{id="58540a34-62ab-46a7-a713-cac112e5cd48"; timeout=180},
    @{id="0e63f087-5446-4033-b826-19dafe65673b"; timeout=600}
)

$changed = 0
foreach ($fix in $fixes) {
    $job = $data.jobs | Where-Object { $_.id -eq $fix.id }
    if ($job) {
        $old = $job.payload.timeoutSeconds
        $job.payload.timeoutSeconds = $fix.timeout
        $job.updatedAtMs = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
        Write-Host "OK $($job.name): $($old)s -> $($fix.timeout)s"
        $changed++
    } else {
        Write-Host "MISS $($fix.id)"
    }
}

# Fix scheduler optimizer delivery
$scheduler = $data.jobs | Where-Object { $_.id -eq "b6bc413c-0228-48c8-b42c-0af833216d2c" }
if ($scheduler) {
    $scheduler.delivery = @{mode="announce"; channel="last"}
    $scheduler.updatedAtMs = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
    Write-Host "OK $($scheduler.name): added delivery config"
    $changed++
    if ($scheduler.payload.timeoutSeconds -lt 600) {
        $old = $scheduler.payload.timeoutSeconds
        $scheduler.payload.timeoutSeconds = 600
        Write-Host "OK $($scheduler.name): timeout $($old)s -> 600s"
        $changed++
    }
}

Write-Host "`nTotal: $changed changes"
$json_out = $data | ConvertTo-Json -Depth 20
# Write with UTF-8 BOM for compatibility
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllText((Resolve-Path $file).Path, $json_out, $Utf8NoBomEncoding)
Write-Host "Saved (UTF-8 no BOM)"
