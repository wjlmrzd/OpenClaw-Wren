$jobsFile = "D:\OpenClaw\.openclaw\cron\jobs.json"
$backupFile = "D:\OpenClaw\.openclaw\cron\jobs.backup.json"

# Model map using task IDs for reliability
$modelMap = @{
    # Keep MiniMax 2.7
    "f36fe701-5c76-47ad-8cb8-1a996a37d1b5" = "minimax-coding-plan/minimax-2.7"  # gateway-predictive-check
    "92af6946-b23b-4534-a6b8-5877cfa36f12" = "minimax-coding-plan/minimax-2.7"  # Health monitor
    "58540a34-62ab-46a7-a713-cac112e5cd48" = "minimax-coding-plan/minimax-2.7"  # Exercise reminder
    "e4248abd-0b9b-4540-9bc5-633547462443" = "minimax-coding-plan/minimax-2.7"  # Regression tester
    
    # qwen3-coder-plus (coding/structure)
    "22b950df-29d8-40a7-8d08-427cb032eabb" = "dashscope-coding-plan/qwen3-coder-plus"  # System self-check
    "b6bc413c-0228-48c8-b42c-0af833216d2c" = "dashscope-coding-plan/qwen3-coder-plus"  # Scheduler
    "98d9b2a8-b925-470b-b0ea-4f74290f3e4b" = "dashscope-coding-plan/qwen3-coder-plus"  # Daily maintenance
    "2b564e59-8ed9-4cd8-8345-a9b41e4349bb" = "dashscope-coding-plan/qwen3-coder-plus"  # Config auditor
    
    # glm-5 (analysis/security)
    "93a63a28-8825-4a68-9c85-5706d9e011ec" = "dashscope-coding-plan/glm-5"  # Feishu reminder
    "53b6edc8-7cc6-4900-ab41-d1abd3e1e15f" = "dashscope-coding-plan/glm-5"  # Security auditor
    "b65e9a07-abbb-4a2d-b2a1-0396e912308e" = "dashscope-coding-plan/glm-5"  # Disaster recovery
    "806f7f0b-f566-452e-a656-6910e5d7531a" = "dashscope-coding-plan/glm-5"  # Disaster drill
    
    # qwen3.5-plus (default for most)
    "0e63f087-5446-4033-b826-19dafe65673b" = "dashscope-coding-plan/qwen3.5-plus"  # Daily news
    "bb0ed170-fa8f-4441-8016-c2119809b436" = "dashscope-coding-plan/qwen3.5-plus"  # Cost analyst
    "afd8aec9-1a66-4bf7-a46a-bedf4490356e" = "dashscope-coding-plan/qwen3.5-plus"  # Morning summary
    "3a1df011-613d-4528-a274-530cfd84f4fb" = "dashscope-coding-plan/qwen3.5-plus"  # Event coordinator
    "f920c2a2-6afc-4fc8-84ad-01593d2d22d1" = "dashscope-coding-plan/qwen3.5-plus"  # Resource guardian
    "ccb233d7-0977-4d57-aba7-7564a67041d8" = "dashscope-coding-plan/qwen3.5-plus"  # Auto-healer
    "7677e68c-a6e7-4d92-8d31-09fb24bb5769" = "dashscope-coding-plan/qwen3.5-plus"  # Knowledge organizer
    "4f5e3918-ce1e-4548-b0c4-97ea5d8c28e5" = "dashscope-coding-plan/qwen3.5-plus"  # Email monitor
    "7eb7f35e-fe72-4a90-bfc6-ed59392b10f6" = "dashscope-coding-plan/qwen3.5-plus"  # Notification coordinator
    "af025901-6ebc-4541-9698-91c5db9907e6" = "dashscope-coding-plan/qwen3.5-plus"  # Log cleaner
    "13f18a92-372a-4076-9b97-08f0efa2377f" = "dashscope-coding-plan/qwen3.5-plus"  # Knowledge evolver
    "b41843c3-9956-4992-860d-df21cd03a766" = "dashscope-coding-plan/qwen3.5-plus"  # Website monitor
    "791c995e-4758-469d-ac35-608da1627167" = "dashscope-coding-plan/qwen3.5-plus"  # Ops director
    "2bb2b058-da87-486a-a400-b871cd5cf8a4" = "dashscope-coding-plan/qwen3.5-plus"  # Project advisor
    "c73f1ecf-9f61-47c5-bea1-1c4f322e2ebe" = "dashscope-coding-plan/qwen3.5-plus"  # Backup admin
    "2428c991-f51e-47d7-8b6d-0035b8aba1e1" = "dashscope-coding-plan/qwen3.5-plus"  # Weekly summary
    "fa18eb23-19af-4176-8e60-990050ba1fab" = "dashscope-coding-plan/qwen3.5-plus"  # Training review
    "3c5f825f-60c8-4a90-9400-1e565ab32eaa" = "dashscope-coding-plan/qwen3.5-plus"  # Tue run
    "e15879fd-59a5-446a-8290-7682fddaca63" = "dashscope-coding-plan/qwen3.5-plus"  # Thu run
    "fae5e00a-aca8-4cb5-aa87-16f4099651aa" = "dashscope-coding-plan/qwen3.5-plus"  # Sat run
    "f84bb934-49bb-4d5b-8bd3-697c43f8cab3" = "dashscope-coding-plan/qwen3.5-plus"  # Sun run
}

Write-Host "Loading jobs..."
$content = Get-Content $jobsFile -Raw -Encoding UTF8
$jobs = $content | ConvertFrom-Json

Write-Host "Found $($jobs.jobs.Count) jobs`n"

$updated = 0
$skipped = 0

foreach ($job in $jobs.jobs) {
    $id = $job.id
    $name = $job.name
    $currentModel = $job.payload.model
    
    if ($modelMap.ContainsKey($id)) {
        $newModel = $modelMap[$id]
        if ($currentModel -ne $newModel) {
            Write-Host "[UPDATE] $($name.Substring(0, [Math]::Min(20, $name.Length)))`: $currentModel -> $newModel"
            $job.payload.model = $newModel
            $updated++
        } else {
            $skipped++
        }
    } else {
        Write-Host "[KEEP]   $($name.Substring(0, [Math]::Min(20, $name.Length)))`: $currentModel (no change needed)"
    }
}

Write-Host "`nUpdated: $updated, Skipped: $skipped"

# Backup and save
Copy-Item $jobsFile $backupFile -Force
$newContent = $jobs | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($jobsFile, $newContent, [System.Text.Encoding]::UTF8)

Write-Host "Done! Backup: $backupFile"
