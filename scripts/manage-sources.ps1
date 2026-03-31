#Requires -Version 5.1

param(
    [switch]$ListRSS,
    [string]$Name,
    [string]$Url,
    [string]$Keywords = "",
    [switch]$Enabled = $true,
    [string]$RemoveRSS,
    [string]$EnableRSS,
    [string]$DisableRSS,
    [switch]$ListKeywords,
    [string]$Target,
    [string]$Keyword,
    [string]$RemoveKeywordTarget,
    [string]$RemoveKeyword,
    [string]$AddTargetName,
    [string]$AddTargetUrl,
    [string]$AddTargetKeywords = "",
    [switch]$AddTargetEnabled = $true,
    [string]$RemoveTarget,
    [string]$EnableTarget,
    [string]$DisableTarget,
    [switch]$ListWebsites,
    [string]$WebsiteName,
    [string]$WebsiteUrl,
    [string]$Categories = "",
    [string]$WebsitePriority = "normal",
    [switch]$WebsiteEnabled = $true,
    [string]$RemoveWebsite,
    [string]$EnableWebsite,
    [string]$DisableWebsite,
    [switch]$RunRSS,
    [switch]$RunKeywords,
    [switch]$RunWebsite,
    [switch]$RunAll,
    [switch]$Interactive
)

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$RSS_CONFIG = Join-Path $SCRIPT_DIR "rss-sources.json"
$KW_CONFIG = Join-Path $SCRIPT_DIR "keyword-monitor-config.json"
$WEBSITE_CONFIG = Join-Path $SCRIPT_DIR "website-monitor-config.json"

function Get-JsonConfig([string]$Path) {
    if (-not (Test-Path $Path)) { Write-Error "Config not found"; return $null }
    return Get-Content $Path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Save-JsonConfig([string]$Path, [object]$Config) {
    $Config | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding UTF8 -NoNewline
    Write-Host "[OK] Saved" -ForegroundColor Green
}

function Parse-Keywords([string]$KeywordStr) {
    if ([string]::IsNullOrWhiteSpace($KeywordStr)) { return @() }
    return ($KeywordStr -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

function Show-RSSList {
    $config = Get-JsonConfig $RSS_CONFIG; if (-not $config) { return }
    Write-Host ""
    Write-Host "[RSS] RSS Sources" -ForegroundColor Cyan
    $sources = @($config.sources)
    if ($sources.Count -eq 0) { Write-Host "  (empty)"; return }
    foreach ($s in $sources) {
        $status = if ($s.enabled) { "[ON]" } else { "[OFF]" }
        $kws = if ($s.keywords) { $s.keywords -join ", " } else { "(none)" }
        Write-Host "  $status $($s.name)" -ForegroundColor Yellow
        Write-Host "    URL: $($s.url)" -ForegroundColor Gray
        Write-Host "    Keywords: $kws"
    }
    Write-Host ""
    Write-Host "Total: $($sources.Count) sources"
}

function Add-RSSSource {
    if ([string]::IsNullOrWhiteSpace($Name) -or [string]::IsNullOrWhiteSpace($Url)) { Write-Error "Need -Name and -Url"; return }
    $config = Get-JsonConfig $RSS_CONFIG; if (-not $config) { return }
    if ($config.sources | Where-Object { $_.name -eq $Name }) { Write-Error "Source exists"; return }
    $config.sources += @{ name = $Name; url = $Url; keywords = Parse-Keywords $Keywords; enabled = [bool]$Enabled; max_items = 10 }
    Save-JsonConfig $RSS_CONFIG $config
    Write-Host "[OK] Added RSS: $Name" -ForegroundColor Green
}

function Remove-RSSSource {
    if ([string]::IsNullOrWhiteSpace($RemoveRSS)) { return }
    $config = Get-JsonConfig $RSS_CONFIG; if (-not $config) { return }
    $initial = $config.sources.Count
    $config.sources = @($config.sources | Where-Object { $_.name -ne $RemoveRSS })
    if ($config.sources.Count -eq $initial) { Write-Error "Not found"; return }
    Save-JsonConfig $RSS_CONFIG $config
    Write-Host "[OK] Removed: $RemoveRSS" -ForegroundColor Green
}

function Toggle-RSSEnabled {
    param([string]$TargetName, [bool]$Enabled)
    $config = Get-JsonConfig $RSS_CONFIG; if (-not $config) { return }
    $source = $config.sources | Where-Object { $_.name -eq $TargetName } | Select-Object -First 1
    if (-not $source) { return }
    $source.enabled = $Enabled
    Save-JsonConfig $RSS_CONFIG $config
    Write-Host "[OK] RSS $TargetName toggled" -ForegroundColor Green
}

function Show-KeywordList {
    $config = Get-JsonConfig $KW_CONFIG; if (-not $config) { return }
    Write-Host ""
    Write-Host "[KEYWORD] Keywords" -ForegroundColor Cyan
    $targets = @($config.targets)
    if ($targets.Count -eq 0) { Write-Host "  (empty)"; return }
    foreach ($t in $targets) {
        $status = if ($t.enabled) { "[ON]" } else { "[OFF]" }
        Write-Host "  $status $($t.name)" -ForegroundColor Yellow
        Write-Host "    URL: $($t.url)" -ForegroundColor Gray
    }
}

function Add-Keyword {
    if ([string]::IsNullOrWhiteSpace($Target) -or [string]::IsNullOrWhiteSpace($Keyword)) { return }
    $config = Get-JsonConfig $KW_CONFIG; if (-not $config) { return }
    $target = $config.targets | Where-Object { $_.name -eq $Target } | Select-Object -First 1
    if (-not $target) { Write-Error "Target not found"; return }
    if ($Keyword -notin $target.keywords) { $target.keywords += $Keyword; Save-JsonConfig $KW_CONFIG $config }
    Write-Host "[OK] Added keyword to $Target" -ForegroundColor Green
}

function Show-WebsiteList {
    if (-not (Test-Path $WEBSITE_CONFIG)) { Write-Host "[WEBSITE] No config"; return }
    $config = Get-Content $WEBSITE_CONFIG -Raw -Encoding UTF8 | ConvertFrom-Json
    $websites = @($config.websites)
    Write-Host ""
    Write-Host "[WEBSITE] Websites" -ForegroundColor Cyan
    if ($websites.Count -eq 0) { Write-Host "  (empty)"; return }
    foreach ($w in $websites) {
        $status = if ($w.enabled) { "[ON]" } else { "[OFF]" }
        $priority = if ($w.priority) { $w.priority } else { "normal" }
        $cats = if ($w.categories) { $w.categories -join ", " } else { "(none)" }
        Write-Host "  $status $($w.name)" -ForegroundColor Yellow
        Write-Host "    URL: $($w.url)" -ForegroundColor Gray
        Write-Host "    Categories: $cats | Priority: $priority"
    }
    Write-Host ""
    Write-Host "Total: $($websites.Count) websites"
}

function Add-MonitorWebsite {
    if ([string]::IsNullOrWhiteSpace($WebsiteName) -or [string]::IsNullOrWhiteSpace($WebsiteUrl)) { Write-Error "Need -WebsiteName and -WebsiteUrl"; return }
    if (-not (Test-Path $WEBSITE_CONFIG)) {
        @{ websites = @(); focus_keywords = @(); max_items_per_site = 5; push_time = "08:00" } | ConvertTo-Json -Depth 10 | Out-File $WEBSITE_CONFIG -Encoding UTF8 -NoNewline
    }
    $config = Get-Content $WEBSITE_CONFIG -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($config.websites | Where-Object { $_.name -eq $WebsiteName }) { Write-Error "Website exists"; return }
    $cats = @()
    if (-not [string]::IsNullOrWhiteSpace($Categories)) { $cats = ($Categories -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }
    $validPriorities = @("low", "normal", "high")
    if ($WebsitePriority -notin $validPriorities) { $WebsitePriority = "normal" }
    $config.websites += @{ name = $WebsiteName; url = $WebsiteUrl; enabled = [bool]$WebsiteEnabled; categories = $cats; priority = $WebsitePriority }
    $config | ConvertTo-Json -Depth 10 | Out-File $WEBSITE_CONFIG -Encoding UTF8 -NoNewline
    Write-Host "[OK] Added website: $WebsiteName" -ForegroundColor Green
}

function Remove-MonitorWebsite {
    if ([string]::IsNullOrWhiteSpace($RemoveWebsite)) { return }
    if (-not (Test-Path $WEBSITE_CONFIG)) { return }
    $config = Get-Content $WEBSITE_CONFIG -Raw -Encoding UTF8 | ConvertFrom-Json
    $initial = $config.websites.Count
    $config.websites = @($config.websites | Where-Object { $_.name -ne $RemoveWebsite })
    if ($config.websites.Count -eq $initial) { Write-Error "Not found"; return }
    $config | ConvertTo-Json -Depth 10 | Out-File $WEBSITE_CONFIG -Encoding UTF8 -NoNewline
    Write-Host "[OK] Removed: $RemoveWebsite" -ForegroundColor Green
}

function Toggle-WebsiteEnabled {
    param([string]$TargetName, [bool]$Enabled)
    if (-not (Test-Path $WEBSITE_CONFIG)) { return }
    $config = Get-Content $WEBSITE_CONFIG -Raw -Encoding UTF8 | ConvertFrom-Json
    $website = $config.websites | Where-Object { $_.name -eq $TargetName } | Select-Object -First 1
    if (-not $website) { return }
    $website.enabled = $Enabled
    $config | ConvertTo-Json -Depth 10 | Out-File $WEBSITE_CONFIG -Encoding UTF8 -NoNewline
    Write-Host "[OK] Website $TargetName toggled" -ForegroundColor Green
}

function Show-InteractiveMenu {
    while ($true) {
        Clear-Host
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  Info Source Manager - Interactive" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  [1] RSS Sources"
        Write-Host "  [2] Keyword Monitor"
        Write-Host "  [3] Website Monitor"
        Write-Host "  [4] Run All Monitors"
        Write-Host "  [5] Exit"
        Write-Host ""
        $choice = Read-Host "Select (1-5)"
        switch ($choice) {
            "1" {
                Show-RSSList
                Write-Host ""
                Write-Host "[A]Add [R]Remove [E]Enable [D]Disable [Q]Back" -ForegroundColor Yellow
                $op = Read-Host "Choice"
                switch ($op.ToUpper()) {
                    "A" { $n = Read-Host "Name"; $u = Read-Host "URL"; if ($n -and $u) { & $MyInvocation.MyCommand.Path -AddRSS -Name $n -Url $u } }
                    "R" { $n = Read-Host "Name to remove"; if ($n) { & $MyInvocation.MyCommand.Path -RemoveRSS -RemoveRSS $n } }
                    "E" { $n = Read-Host "Name to enable"; if ($n) { & $MyInvocation.MyCommand.Path -EnableRSS -EnableRSS $n } }
                    "D" { $n = Read-Host "Name to disable"; if ($n) { & $MyInvocation.MyCommand.Path -DisableRSS -DisableRSS $n } }
                }
            }
            "2" {
                Show-KeywordList
            }
            "3" {
                Show-WebsiteList
                Write-Host ""
                Write-Host "[A]Add [R]Remove [E]Enable [D]Disable [Q]Back" -ForegroundColor Yellow
                $op = Read-Host "Choice"
                switch ($op.ToUpper()) {
                    "A" {
                        $n = Read-Host "Website name"
                        $u = Read-Host "URL"
                        $c = Read-Host "Categories (comma sep, optional)"
                        $p = Read-Host "Priority (low/normal/high, default normal)"
                        $priority = if ($p) { $p } else { "normal" }
                        if ($n -and $u) { & $MyInvocation.MyCommand.Path -AddWebsite -WebsiteName $n -WebsiteUrl $u -Categories $c -WebsitePriority $priority }
                    }
                    "R" { $n = Read-Host "Name to remove"; if ($n) { & $MyInvocation.MyCommand.Path -RemoveWebsite -RemoveWebsite $n } }
                    "E" { $n = Read-Host "Name to enable"; if ($n) { & $MyInvocation.MyCommand.Path -EnableWebsite -EnableWebsite $n } }
                    "D" { $n = Read-Host "Name to disable"; if ($n) { & $MyInvocation.MyCommand.Path -DisableWebsite -DisableWebsite $n } }
                }
            }
            "4" { & $MyInvocation.MyCommand.Path -RunAll }
            "5" { Write-Host "Bye!" -ForegroundColor Green; return }
            default { Write-Host "Invalid" -ForegroundColor Red }
        }
        if ($choice -ne "5") { Write-Host ""; Read-Host "Press Enter to continue" }
    }
}

if ($ListRSS) { Show-RSSList }
elseif ($Name -and $Url) { Add-RSSSource }
elseif ($RemoveRSS) { Remove-RSSSource }
elseif ($EnableRSS) { Toggle-RSSEnabled -TargetName $EnableRSS -Enabled $true }
elseif ($DisableRSS) { Toggle-RSSEnabled -TargetName $DisableRSS -Enabled $false }
elseif ($ListKeywords) { Show-KeywordList }
elseif ($Target -and $Keyword) { Add-Keyword }
elseif ($ListWebsites) { Show-WebsiteList }
elseif ($WebsiteName -and $WebsiteUrl) { Add-MonitorWebsite }
elseif ($RemoveWebsite) { Remove-MonitorWebsite }
elseif ($EnableWebsite) { Toggle-WebsiteEnabled -TargetName $EnableWebsite -Enabled $true }
elseif ($DisableWebsite) { Toggle-WebsiteEnabled -TargetName $DisableWebsite -Enabled $false }
elseif ($RunAll) {
    Write-Host "[RUN] Running all monitors..." -ForegroundColor Cyan
    python (Join-Path $SCRIPT_DIR "website-monitor.py")
    python (Join-Path $SCRIPT_DIR "rss-monitor.py")
    python (Join-Path $SCRIPT_DIR "keyword-monitor.py")
}
elseif ($Interactive) { Show-InteractiveMenu }
else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Info Source Manager" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "RSS:"
    Write-Host "  -ListRSS"
    Write-Host "  -AddRSS -Name xxx -Url url"
    Write-Host "  -RemoveRSS -RemoveRSS xxx"
    Write-Host "  -EnableRSS -EnableRSS xxx"
    Write-Host "  -DisableRSS -DisableRSS xxx"
    Write-Host ""
    Write-Host "Keywords:"
    Write-Host "  -ListKeywords"
    Write-Host "  -AddKeyword -Target xxx -Keyword yyy"
    Write-Host ""
    Write-Host "Website:"
    Write-Host "  -ListWebsites"
    Write-Host "  -AddWebsite -WebsiteName xxx -WebsiteUrl url"
    Write-Host "  -AddWebsite -WebsiteName xxx -WebsiteUrl url -Categories cat1,cat2 -WebsitePriority high"
    Write-Host "  -RemoveWebsite -RemoveWebsite xxx"
    Write-Host "  -EnableWebsite -EnableWebsite xxx"
    Write-Host "  -DisableWebsite -DisableWebsite xxx"
    Write-Host ""
    Write-Host "Run:"
    Write-Host "  -RunAll"
    Write-Host ""
    Write-Host "Interactive Menu:"
    Write-Host "  -Interactive"
}
