$lines = Get-Content 'D:\OpenClaw\.openclaw\workspace\plugins-lossless-claw-enhanced\src\plugin\index.ts'
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match 'registerContextEngine') {
        $start = [Math]::Max(0, $i-3)
        $end = [Math]::Min($lines.Count-1, $i+3)
        for ($j = $start; $j -le $end; $j++) {
            $marker = if ($j -eq $i) { ">>>" } else { "   " }
            Write-Host "$marker $($j+1): $($lines[$j])"
        }
        break
    }
}
