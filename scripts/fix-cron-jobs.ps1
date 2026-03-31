$content = Get-Content 'D:\OpenClaw\.openclaw\cron\jobs.json' -Raw -Encoding UTF8
$json = $content | ConvertFrom-Json

$changes = @()

# 1. 禁用通知协调员
$job = $json.jobs | Where-Object { $_.id -eq '7eb7f35e-fe72-4a90-bfc6-ed59392b10f6' }
if ($job) { $job.enabled = $false; $job.updatedAtMs = [int64](Get-Date -UFormat '%s') * 1000; $changes += '通知协调员: disabled' }

# 2. 禁用资源守护者
$job = $json.jobs | Where-Object { $_.id -eq 'f920c2a2-6afc-4fc8-84ad-01593d2d22d1' }
if ($job) { $job.enabled = $false; $job.updatedAtMs = [int64](Get-Date -UFormat '%s') * 1000; $changes += '资源守护者: disabled' }

# 3. 禁用配置优化员
$job = $json.jobs | Where-Object { $_.id -eq '16c5208a-e77c-4b6f-a8be-eb6e62807a07' }
if ($job) { $job.enabled = $false; $job.updatedAtMs = [int64](Get-Date -UFormat '%s') * 1000; $changes += '配置优化员: disabled' }

# 4. 禁用每日信息汇总
$job = $json.jobs | Where-Object { $_.id -eq 'b8665efb-6e32-4a0b-b9ed-39ed69c69185' }
if ($job) { $job.enabled = $false; $job.updatedAtMs = [int64](Get-Date -UFormat '%s') * 1000; $changes += '每日信息汇总: disabled' }

# 5. 禁用 RSS 订阅监控
$job = $json.jobs | Where-Object { $_.id -eq 'a9fde676-177e-4c4e-9b1d-a54133e84a8e' }
if ($job) { $job.enabled = $false; $job.updatedAtMs = [int64](Get-Date -UFormat '%s') * 1000; $changes += 'RSS订阅监控: disabled' }

# 6. 禁用知识管理三元组
$job = $json.jobs | Where-Object { $_.id -eq 'ddd96cfb-f017-475e-8b2b-34c522b9ddae' }
if ($job) { $job.enabled = $false; $job.updatedAtMs = [int64](Get-Date -UFormat '%s') * 1000; $changes += '知识管理三元组: disabled' }

# 7. 禁用运营总监 (超时 + 与项目顾问重叠)
$job = $json.jobs | Where-Object { $_.id -eq '791c995e-4758-469d-ac35-608da1627167' }
if ($job) { $job.enabled = $false; $job.updatedAtMs = [int64](Get-Date -UFormat '%s') * 1000; $changes += '运营总监: disabled (超时+重叠)' }

# 8. 安全审计员 - 确保禁用
$job = $json.jobs | Where-Object { $_.id -eq '53b6edc8-7cc6-4900-ab41-d1abd3e1e15f' }
if ($job) { $job.enabled = $false; $job.updatedAtMs = [int64](Get-Date -UFormat '%s') * 1000; $changes += '安全审计员: disabled (确认)' }

# 9. 健康监控员 - 已通过 edit 改频率，这里确认
$job = $json.jobs | Where-Object { $_.id -eq '92af6946-b23b-4534-a6b8-5877cfa36f12' }
if ($job) {
    $oldExpr = $job.schedule.expr
    $job.schedule.expr = '5 */5 * * *'
    $job.updatedAtMs = [int64](Get-Date -UFormat '%s') * 1000
    $changes += "健康监控员: 频率 $oldExpr -> 5 */5 * * * (每5分钟)"
}

$json | ConvertTo-Json -Depth 20 | Set-Content 'D:\OpenClaw\.openclaw\cron\jobs.json' -Encoding UTF8

Write-Host "=== 任务精简完成 ==="
$changes | ForEach-Object { Write-Host $_ }
Write-Host "=== 总计禁用/修改: $($changes.Count) 个 ==="
