# Knowledge Organizer - 知识整理脚本
# Architecture: OpenClaw → 00-Inbox → knowledge_organizer → 正式目录

$ErrorActionPreference = "Stop"
$BasePath = "D:\OpenClaw\.openclaw\workspace\OpenClaw"
$InboxPath = "$BasePath\00-Inbox"
$KnowledgePath = "$BasePath\01-Knowledge"
$ProjectsPath = "$BasePath\02-Projects"
$SystemPath = "$BasePath\03-System"
$IssuesPath = "$BasePath\04-Issues"
$LogPath = "D:\OpenClaw\.openclaw\workspace\memory\knowledge-organizer-log.md"
$StatePath = "D:\OpenClaw\.openclaw\workspace\memory\knowledge-organizer-state.json"
$ReportPath = "D:\OpenClaw\.openclaw\workspace\memory\knowledge-organizer-report.md"
$IgnorePatterns = "^概念 [A-Z]$|^概念 [A-Z] 备份$|^笔记 [A-Z]$|^相关概念 \d+$|^潜在概念$|^缺失概念$|^\.\.\.$|^示例$|^显示文本$|^主题名称$|^链接$"

function Log { param($M,$L="INFO"); Add-Content -Path $LogPath -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$L] $M" -Encoding UTF8 }
Log "========== Start =========="

# 确保目录
foreach ($d in @($InboxPath,"$BasePath\knowledge_organizer",$KnowledgePath,$ProjectsPath,$SystemPath,$IssuesPath)) {
    if (!(Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null; Log "Created: $d" }
}

# Inbox 扫描
$inbox = Get-ChildItem -Path $InboxPath -Filter "*.md" -File -ErrorAction SilentlyContinue
$ic = if($inbox){$inbox.Count}else{0}
Log "Inbox: $ic"

# Inbox → 正式
$mv=0
if($inbox){
  foreach($n in $inbox){
    try{
      $c=[IO.File]::ReadAllText($n.FullName,[Text.UTF8Encoding]::new($false))
      $tc="01-Knowledge"
      if($c -match "type:\s*spec"){$tc="03-System"}elseif($c -match "type:\s*project"){$tc="02-Projects"}elseif($c -match "type:\s*issue"){$tc="04-Issues"}
      $tp="$BasePath\$tc\$($n.Name)"
      if(!(Test-Path $tp)){Move-Item $n.FullName $tp -Force;$mv++;Log "Moved: $($n.Name)"}else{Log "Skip: $($n.Name)" "WARN"}
    }catch{Log "Error: $($_)" "ERROR"}
  }
}

# 正式目录扫描
$notes=@()
foreach($p in @($KnowledgePath,$ProjectsPath,$SystemPath,$IssuesPath)){if(Test-Path $p){$notes+=Get-ChildItem -Path $p -Filter "*.md" -File}}
$total=$notes.Count
Log "Formal: $total"

# 解析标题
$titles=@{}
foreach($n in $notes){
  try{
    $c=[IO.File]::ReadAllText($n.FullName,[Text.UTF8Encoding]::new($false))
    $m=[regex]::Match($c,"^# {{(.+)}}")
    if($m.Success){$titles[$m.Groups[1].Value.Trim()]=$n.FullName}
  }catch{}
}
Log "Titles: $($titles.Count)"

# 断链检测
$broken=@()
foreach($n in $notes){
  try{
    $c=[IO.File]::ReadAllText($n.FullName,[Text.UTF8Encoding]::new($false))
    [regex]::Matches($c,'\[\[([^\]]+)\]')|ForEach-Object{
      $cl=(($_.Groups[1].Value-split'\|')[0]-split'#')[0].Trim()
      if($cl -and !$titles.ContainsKey($cl) -and $cl-notmatch $IgnorePatterns){$broken+=$cl;Log "Broken: $cl in $($n.Name)" "WARN"}
    }
  }catch{}
}
$bu=$broken|Select-Object -Unique
Log "Broken: $($bu.Count)"

# 创建空壳
$cr=@()
foreach($b in $bu){
  if(!$b){continue}
  $sf=$b-replace'[\\/:*?"<>|]',''
  $fp="$InboxPath\$sf.md"
  if(!(Test-Path $fp)){
    $dt=Get-Date -Format 'yyyy-MM-dd'
    $sh="# {{$b}}`n`n## Overview`nTODO`n`n## Key`n- TODO`n`n## Details`nTODO`n`n## Related`n- TODO`n`n---`ntags:[todo]`ncreated:$dt`nsource:openclaw`ntype:note`n"
    [IO.File]::WriteAllText($fp,$sh,[Text.UTF8Encoding]::new($false))
    $cr+=$b;Log "Shell: $b"
  }
}

# 统计
$cats=@{}
foreach($ct in @("00-Inbox","01-Knowledge","02-Projects","03-System","04-Issues")){$cats[$ct]=if(Test-Path "$BasePath\$ct"){(Get-ChildItem "$BasePath\$ct" -Filter "*.md" -File).Count}else{0}}

# 指标
$br=if($titles.Count-gt0){[math]::Round($bu.Count/$titles.Count*100,2)}else{0}
$cv=if($titles.Count-gt0){[math]::Round(($titles.Count-$bu.Count)/$titles.Count*100,2)}else{100}

# 报告
$rpt="# Report`n`n**Time**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n## Summary`n- Inbox:$ic`n- Moved:$mv`n- Formal:$total`n- Broken:$($bu.Count)`n- Shells:$($cr.Count)`n`n## Categories`n"
foreach($k in $cats.Keys){$rpt+="- $k`: $($cats[$k])`n"}
$rpt+="`n## Shells`n"
if($cr.Count-eq0){$rpt+="- (none)`n"}else{$cr|ForEach-Object{$rpt+="- $_`n"}}
$rpt+="`n## Metrics`n- Rate: ${br}%`n- Coverage: ${cv}%`n`n---`nAuto`n"
[IO.File]::WriteAllText($ReportPath,$rpt,[Text.UTF8Encoding]::new($false))

# 状态
$st=[pscustomobject]@{lastRun=Get-Date -Format "yyyy-MM-dd HH:mm:ss";inbox=$ic;moved=$mv;total=$total;broken=$bu.Count;shells=$cr.Count;cats=$cats;met=[pscustomobject]@{rate=$br;cov=$cv}}
[IO.File]::WriteAllText($StatePath,($st|ConvertTo-Json -Depth 5),[Text.UTF8Encoding]::new($false))

Log "========== Done =========="
Write-Host "Inbox:$ic Moved:$mv Notes:$total Broken:$($bu.Count) Shells:$($cr.Count)" -ForegroundColor Green
