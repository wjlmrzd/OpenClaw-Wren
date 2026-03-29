# 检查 jobs.json 编码
$bytes = [System.IO.File]::ReadAllBytes('D:\OpenClaw\.openclaw\workspace\cron\jobs.json')
$bom = ''
if ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { $bom = 'UTF-8 BOM' }
elseif ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) { $bom = 'UTF-16 LE' }
elseif ($bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) { $bom = 'UTF-16 BE' }
else { $bom = 'No BOM' }
Write-Host "Encoding: $bom"

# 尝试用 Python 解析
python -c "import json; json.load(open(r'D:\OpenClaw\.openclaw\workspace\cron\jobs.json', 'r', encoding='utf-8')); print('JSON valid')" 2>&1
