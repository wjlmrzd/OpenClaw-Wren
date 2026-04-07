# Find lossless-claw / LCM compressed files
$dirs = @(
    "D:\OpenClaw\.openclaw",
    "D:\OpenClaw\.openclaw\workspace\plugins-lossless-claw-enhanced",
    "D:\OpenClaw\.openclaw\workspace\plugins-graph-memory"
)

foreach ($dir in $dirs) {
    if (Test-Path $dir) {
        Write-Host "=== Scanning: $dir ==="
        Get-ChildItem $dir -Recurse -Depth 4 -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match "summary|lcm|compact|graph|chunk|node" -or $_.Extension -match "\.jsonl|\.json|\.db|\.sqlite" } |
            Select-Object FullName, Length, LastWriteTime |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 10
        Write-Host ""
    }
}
