$file = "D:\OpenClaw\.openclaw\workspace\cron\jobs.json"
$content = Get-Content $file -Raw

# 替换各种模型为 minimax-2.7
$replacements = @(
    "dashscope-coding-plan/qwen3.5-plus",
    "dashscope-coding-plan/qwen3-coder-plus",
    "dashscope-coding-plan/qwen3-coder-next",
    "dashscope-coding-plan/glm-5",
    "dashscope-coding-plan/glm-4.7",
    "dashscope-coding-plan/kimi-k2.5",
    "dashscope-coding-plan/minimax-m2.5",
    "qwen3.5-plus",
    "qwen3-coder-plus",
    "qwen3-coder-next",
    "glm-5",
    "glm-4.7",
    "kimi-k2.5",
    "minimax-m2.5"
)

$newModel = "minimax-coding-plan/minimax-2.7"
$totalCount = 0

foreach ($old in $replacements) {
    if ($content -match [regex]::Escape($old)) {
        $matches = ([regex]::Matches($content, [regex]::Escape($old))).Count
        $content = $content -replace [regex]::Escape($old), $newModel
        Write-Host "Replaced $matches x '$old'"
        $totalCount += $matches
    }
}

Set-Content -Path $file -Value $content -Encoding UTF8
Write-Host ""
Write-Host "Total: Replaced $totalCount model references with $newModel"
