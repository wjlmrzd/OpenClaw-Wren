$ErrorActionPreference='Stop'
$repo='D:\OpenClaw\.openclaw\workspace'
$gatewayUrl='http://localhost:18789'
$token=$null
try{
  $cfg=Get-Content "$repo\openclaw.json" -Raw -Encoding UTF8 | ConvertFrom-Json
  $token=$cfg.resolved.gateway.auth.token
}catch{
  Write-Host '[C]No config'
  exit 0
}
if(-not $token){exit 0}
$hdrs=@{Authorization="Bearer $token";'Content-Type'='application/json'}
$h=(Get-Date).Hour
if($h -lt 7 -or $h -ge 23){Write-Host '[C]Night';exit 0}
if((Get-Random -Maximum 100) -gt 15){Write-Host '[C]RandSkip';exit 0}
$sf="$repo\memory\companion\state.json"
$d=Split-Path $sf -Parent
if(-not(Test-Path $d)){New-Item -ItemType Directory -Path $d -Force|Out-Null}
if(-not(Test-Path $sf)){$st=@{lm=$null;c=0};$st|ConvertTo-Json|Set-Content $sf -Encoding UTF8}
$st=Get-Content $sf -Raw -Encoding UTF8|ConvertFrom-Json
if($st.lm){$s=((Get-Date).ToUniversalTime().Ticks-$st.lm)/36000000;if($s -lt 4){Write-Host '[C]Soon';exit 0}}
$d=(Get-Date).DayOfWeek.Value__
$m=@{}
if($h -ge 7 -and $h -lt 9){$m['g']='早上好 Wren！新的一天开始了 ☀️';if($d -in @(2,4,6,0)){$m['x']='今天是跑步日，记得去训练 🏃'}}
if($h -ge 10 -and $h -lt 12){$m['c']='上午工作中，有什么需要我帮忙的吗？'}
if($h -eq 12){$m['l']='午休时间，记得吃午饭 🍱'}
if($h -ge 14 -and $h -lt 17){$m['a']='下午好，今天进展怎么样？'}
if($h -ge 17 -and $h -lt 18){$m['e']='快下班了，今天的主要任务完成了吗？'}
if($h -ge 20 -and $h -lt 22){$m['v']='晚上好，还有什么需要处理的吗？'}
$msg=$null
if($m['x']){$msg=$m['x']}elseif($m['e']){$msg=$m['e']}elseif($m['a']){$msg=$m['a']}elseif($m['c']){$msg=$m['c']}elseif($m['v']){$msg=$m['v']}elseif($m['l']){$msg=$m['l']}elseif($m['g']){$msg=$m['g']}
if(-not $msg){Write-Host '[C]NoMsg';exit 0}
Write-Host ('[C]SENDING:'+$msg)
try{
  $b=@{channel='telegram';target='-1003866951105';message=$msg;threadId='166'}|ConvertTo-Json -Compress
  Invoke-RestMethod -Uri "$gatewayUrl/api/chat/send" -Method POST -Headers $hdrs -Body $b -TimeoutSec 10
  $st.lm=(Get-Date).ToUniversalTime().Ticks
  $st.c=if($st.c){$st.c+1}else{1}
  $st|ConvertTo-Json|Set-Content $sf -Encoding UTF8
  Write-Host '[C]OK'
}catch{Write-Host ('[C]ERR:'+$_.Exception.Message);exit 1}
