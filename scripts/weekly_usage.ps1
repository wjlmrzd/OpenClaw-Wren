# Weekly Token Usage Aggregation
# Week: March 29 - April 5, 2026

$weekAgo = (Get-Date).AddDays(-7)
$hash = @{}

Get-ChildItem "D:\OpenClaw\.openclaw\agents\main\sessions" -Filter "*.jsonl" -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -gt $weekAgo } | ForEach-Object {
    $lines = Get-Content $_.FullName -ErrorAction SilentlyContinue
    foreach ($line in $lines) {
        try {
            $j = $line | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($j.usage -and $j.usage.totalTokens -gt 0) {
                $model = if ($j.model) { $j.model } elseif ($j.usage.model) { $j.usage.model } else { "unknown" }
                $provider = if ($j.provider) { $j.provider } else { "unknown" }
                $key = "$($provider)/$($model)"
                if (-not $hash.ContainsKey($key)) {
                    $hash[$key] = @{ input=0; output=0; cacheRead=0; cacheWrite=0; totalTokens=0; calls=0 }
                }
                $hash[$key].input += [int]($j.usage.input ?? 0)
                $hash[$key].output += [int]($j.usage.output ?? 0)
                $hash[$key].cacheRead += [int]($j.usage.cacheRead ?? 0)
                $hash[$key].cacheWrite += [int]($j.usage.cacheWrite ?? 0)
                $hash[$key].totalTokens += [int]($j.usage.totalTokens ?? 0)
                $hash[$key].calls++
            }
        } catch {}
    }
}

Write-Output "=== WEEKLY TOKEN USAGE REPORT (Mar 29 - Apr 5, 2026) ==="
Write-Output "Total sessions processed: $(Get-ChildItem 'D:\OpenClaw\.openclaw\agents\main\sessions' -Filter '*.jsonl' -ErrorAction SilentlyContinue | Where-Object { `$_.LastWriteTime -gt `$weekAgo } | Measure-Object).Count"
Write-Output ""
Write-Output "MODEL BREAKDOWN:"
Write-Output "----------------"
$totalInput = 0; $totalOutput = 0; $totalCacheRead = 0; $totalCacheWrite = 0; $totalTotal = 0; $totalCalls = 0
foreach ($k in $hash.Keys | Sort-Object) {
    $v = $hash[$k]
    $v.inputM = [math]::Round($v.input/1000000, 4)
    $v.outputM = [math]::Round($v.output/1000000, 4)
    $v.cacheReadM = [math]::Round($v.cacheRead/1000000, 4)
    $v.cacheWriteM = [math]::Round($v.cacheWrite/1000000, 4)
    $v.totalM = [math]::Round($v.totalTokens/1000000, 4)
    Write-Output "$k"
    Write-Output "  Calls: $($v.calls) | Input: $($v.input) ($($v.inputM)M) | Output: $($v.output) ($($v.outputM)M) | CacheRead: $($v.cacheRead) ($($v.cacheReadM)M) | CacheWrite: $($v.cacheWrite) ($($v.cacheWriteM)M) | Total: $($v.totalTokens) ($($v.totalM)M)"
    $totalInput += $v.input; $totalOutput += $v.output
    $totalCacheRead += $v.cacheRead; $totalCacheWrite += $v.cacheWrite
    $totalTotal += $v.totalTokens; $totalCalls += $v.calls
}
Write-Output ""
Write-Output "TOTALS:"
Write-Output "  Calls: $totalCalls"
Write-Output "  Input: $totalInput tokens"
Write-Output "  Output: $totalOutput tokens"
Write-Output "  CacheRead: $totalCacheRead tokens"
Write-Output "  CacheWrite: $totalCacheWrite tokens"
Write-Output "  Total: $totalTotal tokens ($([math]::Round($totalTotal/1000000, 4))M)"
Write-Output ""
Write-Output "Note: MiniMax calls may show cost=0 in session data (bundled pricing)."
Write-Output "Check MiniMax dashboard for actual costs."
