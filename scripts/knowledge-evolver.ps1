# Knowledge Evolver
$BasePath = "D:\OpenClaw\.openclaw\workspace\OpenClaw"
$LogPath = "D:\OpenClaw\.openclaw\workspace\memory\knowledge-evolver-log.md"
$ReportPath = "D:\OpenClaw\.openclaw\workspace\memory\knowledge-evolver-report.md"
$StatePath = "D:\OpenClaw\.openclaw\workspace\memory\knowledge-evolver-state.json"

function Log { param($M,$L="INFO"); Add-Content $LogPath -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$L] $M" -Encoding UTF8 }
Log "========== Start =========="

# Scan
$notes = @()
foreach ($p in @("$BasePath\01-Knowledge","$BasePath\03-System")) {
    if (Test-Path $p) { $notes += Get-ChildItem $p -Filter "*.md" -File }
}
$total = $notes.Count
Log "Total: $total"

# Parse
$nodes = @{}
foreach ($n in $notes) {
    $c = [IO.File]::ReadAllText($n.FullName, [Text.UTF8Encoding]::new($false))
    $m = [regex]::Match($c, "^# {{(.+)}}")
    $t = if ($m.Success) { $m.Groups[1].Value.Trim() } else { $n.BaseName }
    $type = if ($c -match "type:\s*(\w+)") { $matches[1] } else { "concept" }
    $links = [regex]::Matches($c, '\[\[([^\]]+)\]') | ForEach-Object { $_.Groups[1].Value }
    $nodes[$t] = @{ Title=$t; Type=$type; Links=$links; Count=$links.Count }
}
Log "Nodes: $($nodes.Count)"

# Isolated (links < 2)
$iso = @()
foreach ($k in $nodes.Keys) { if ($nodes[$k].Count -lt 2) { $iso += $k; Log "Iso: $k" "WARN" } }
Log "Isolated: $($iso.Count)"

# Duplicates
$dup = @()
$titles = $nodes.Keys | Sort-Object
for ($i = 0; $i -lt $titles.Count; $i++) {
    for ($j = $i + 1; $j -lt $titles.Count; $j++) {
        if ($titles[$i].Contains($titles[$j]) -or $titles[$j].Contains($titles[$i])) {
            $dup += "$($titles[$i]) / $($titles[$j])"
            Log "Dup: $($titles[$i]) vs $($titles[$j])" "WARN"
        }
    }
}
Log "Duplicates: $($dup.Count)"

# Stats
$themes = ($nodes.Values | Where-Object { $_.Type -eq 'system' -and $_.Count -ge 5 }).Count
$modules = ($nodes.Values | Where-Object { $_.Type -eq 'concept' -or ($_.Type -eq 'system' -and $_.Count -lt 5) }).Count

# Graph
$g = "graph TD`n    KM[Knowledge System]`n"
foreach ($n in $nodes.Values | Where-Object { $_.Type -eq 'system' }) {
    $s = $n.Title -replace '\s+',''
    $g += "    KM --> $s[$($n.Title)]`n"
}

# Report
$r = "# Evolver Report`n`n$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
$r += "## Summary`n- Total: $total`n- Isolated: $($iso.Count)`n- Duplicates: $($dup.Count)`n- Themes: $themes`n- Modules: $modules`n`n"
$r += "## Isolated`n"
if ($iso.Count -eq 0) { $r += "- none`n" } else { $iso | ForEach-Object { $r += "- $_`n" } }
$r += "## Graph`n`n`n$g`n`n---`nAuto`n"
[IO.File]::WriteAllText($ReportPath, $r, [Text.UTF8Encoding]::new($false))

# State
$st = @{ lastRun = Get-Date -Format "yyyy-MM-dd HH:mm:ss"; total=$total; isolated=$iso.Count; dup=$dup.Count }
[IO.File]::WriteAllText($StatePath, ($st | ConvertTo-Json), [Text.UTF8Encoding]::new($false))

Log "========== Done =========="
Write-Host "Total:$total Iso:$($iso.Count) Dup:$($dup.Count)" -ForegroundColor Green
