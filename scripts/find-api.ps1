$pattern = "registerContextEngine"
$paths = @(
    "D:\OpenClaw\.openclaw\workspace\plugins-graph-memory",
    "D:\OpenClaw\.openclaw\workspace\plugins-lossless-claw-enhanced"
)
foreach ($p in $paths) {
    Write-Host "=== Searching in $p ==="
    Get-ChildItem $p -Recurse -Include *.ts | ForEach-Object {
        $lines = Get-Content $_.FullName
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            if ($line -match [regex]::Escape($pattern)) {
                Write-Host "$($_.FullName):$($i+1): $($line)"
            }
        }
    }
}
