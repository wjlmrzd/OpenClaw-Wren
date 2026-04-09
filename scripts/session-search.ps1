# Session Search Script
# 在归档会话文件中搜索关键词，输出匹配片段

param(
    [Parameter(Mandatory=$true)]
    [string]$Query,
    [int]$Days = 7,
    [int]$Limit = 10
)

$openclawDir = "D:\OpenClaw\.openclaw"
$sessionsDir = Join-Path $openclawDir "memory\sessions"
$Cutoff = (Get-Date).AddDays(-$Days)

if (-not (Test-Path $sessionsDir)) {
    Write-Host "No sessions archived yet"
    exit 0
}

$files = Get-ChildItem $sessionsDir -Filter "*.jsonl" | Where-Object { $_.LastWriteTime -gt $Cutoff } | Sort-Object LastWriteTime -Descending

$results = @()
foreach ($file in $files) {
    $lines = Get-Content $file.FullName -Encoding UTF8 | Where-Object { $_ -ne "" }
    foreach ($line in $lines) {
        $msg = ConvertFrom-Json $line
        if ($msg.content -and $msg.content -match $Query) {
            $snippet = $msg.content.Substring(0, [Math]::Min(200, $msg.content.Length))
            if ($msg.content.Length -gt 200) { $snippet += "..." }
            $results += [PSCustomObject]@{
                file = $file.Name
                ts   = $msg.ts
                role = $msg.role
                snippet = $snippet
            }
            if ($results.Count -ge $Limit) { break }
        }
    }
    if ($results.Count -ge $Limit) { break }
}

if ($results.Count -eq 0) {
    Write-Host "No matches found for: $Query"
} else {
    Write-Host "=== Session Search: '$Query' ($($results.Count) matches) ==="
    foreach ($r in $results) {
        Write-Host ""
        Write-Host "[$($r.ts)] [$($r.role)]"
        Write-Host $r.snippet
    }
}
