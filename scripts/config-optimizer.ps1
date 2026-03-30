# config-optimizer.ps1 - OpenClaw Config Optimizer
# Daily at 03:30 - Check and optimize openclaw.json

param(
    [switch]$DryRun,
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"

# Config
$ConfigPath = "D:\OpenClaw\.openclaw\openclaw.json"
$StateFile = "D:\OpenClaw\.openclaw\workspace\memory\config-optimizer-state.json"
$LogFile = "D:\OpenClaw\.openclaw\workspace\memory\config-optimizer-log.md"
$MaxTokensMin = 4096
$MaxTokensMax = 16384

# State
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$runId = [guid]::NewGuid().ToString().Substring(0, 8)
$autoChanges = @()
$reportItems = @()
$needsRestart = $false

function Write-Log {
    param($Level, $Message)
    $color = "White"
    $prefix = "[    ]"
    if ($Level -eq "INFO")  { $color = "White"; $prefix = "[INFO]" }
    if ($Level -eq "WARN")  { $color = "Yellow"; $prefix = "[WARN]" }
    if ($Level -eq "ERROR") { $color = "Red"; $prefix = "[ERR ]" }
    if ($Level -eq "OK")    { $color = "Green"; $prefix = "[ OK ]" }
    if ($Level -eq "OPT")   { $color = "Cyan"; $prefix = "[OPT ]" }
    if ($Verbose -or $Level -eq "ERROR" -or $Level -eq "WARN") {
        Write-Host "$prefix $Message" -ForegroundColor $color
    }
}

# Load config
Write-Log "INFO" "Loading config file..."
$configRaw = Get-Content $ConfigPath -Raw -Encoding UTF8
$config = $configRaw | ConvertFrom-Json

# Check 1: Logging level
Write-Log "INFO" "Checking logging level..."
$currentLevel = $config.logging.level
if ($currentLevel -eq "debug") {
    Write-Log "OPT" "logging.level: debug -> info"
    $autoChanges += "logging.level: debug -> info (reduce noise)"
    if (-not $DryRun) {
        $config.logging.level = "info"
    }
} else {
    Write-Log "OK" "logging.level: $currentLevel (OK)"
}

# Check 2: meta.lastTouchedAt
Write-Log "INFO" "Checking meta info..."
$lastTouched = $config.meta.lastTouchedAt
if ($lastTouched) {
    try {
        $ts = [DateTime]::Parse($lastTouched)
        $daysSince = ((Get-Date) - $ts).Days
        Write-Log "INFO" "lastTouchedAt: $lastTouched ($daysSince days ago)"
    } catch {
        Write-Log "WARN" "lastTouchedAt parse failed: $lastTouched"
    }
}
if (-not $DryRun) {
    $config.meta.lastTouchedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
}

# Check 3: Model input fields
Write-Log "INFO" "Checking model input fields..."
$expectedInputs = @{}
$expectedInputs["qwen3.5-plus"] = @("text", "image")
$expectedInputs["qwen3-coder-plus"] = @("text")
$expectedInputs["qwen3-coder-next"] = @("text")
$expectedInputs["glm-5"] = @("text")
$expectedInputs["glm-4.7"] = @("text")
$expectedInputs["kimi-k2.5"] = @("text", "image")
$expectedInputs["minimax-2.7"] = @("text", "image")
$expectedInputs["minimax-m2.5"] = @("text")

$allModels = @()
$dsModels = $config.models.providers.'dashscope-coding-plan'.models
$minimaxModels = $config.models.providers.'minimax-coding-plan'.models
$dsModels | ForEach-Object { $allModels += $_.id }
$minimaxModels | ForEach-Object { $allModels += $_.id }

$inputIssues = 0
foreach ($modelId in $allModels) {
    $expected = $expectedInputs[$modelId]
    if ($expected) {
        $providerName = if ($dsModels.id -contains $modelId) { "dashscope" } else { "minimax" }
        $modelObj = if ($providerName -eq "dashscope") {
            ($dsModels | Where-Object { $_.id -eq $modelId })
        } else {
            ($minimaxModels | Where-Object { $_.id -eq $modelId })
        }
        $current = @($modelObj.input)
        $match = $true
        if ($current.Count -ne $expected.Count) { $match = $false }
        else {
            foreach ($e in $expected) {
                if ($current -notcontains $e) { $match = $false }
            }
        }
        if ($match) {
            Write-Log "OK" "  $modelId : [$($current -join ',')] OK"
        } else {
            Write-Log "WARN" "  $modelId : current [$($current -join ',')] expected [$($expected -join ',')]"
            $inputIssues++
        }
    }
}
if ($inputIssues -eq 0) {
    $reportItems += "All model input fields correct"
} else {
    $reportItems += "WARNING: $inputIssues model(s) with incorrect input fields"
}

# Check 4: maxTokens
Write-Log "INFO" "Checking maxTokens..."
$tokensIssues = 0
foreach ($modelId in $allModels) {
    $modelObj = if ($dsModels.id -contains $modelId) {
        ($dsModels | Where-Object { $_.id -eq $modelId })
    } else {
        ($minimaxModels | Where-Object { $_.id -eq $modelId })
    }
    $mt = $modelObj.maxTokens
    $cw = $modelObj.contextWindow
    $ok = $true
    if ($mt -lt $MaxTokensMin -or $mt -gt $MaxTokensMax) { $ok = $false; $tokensIssues++ }
    if ($mt -gt $cw) { $ok = $false; $tokensIssues++ }
    $flag = if ($ok) { "OK" } else { "WARN" }
    Write-Log $flag "  $modelId : maxTokens=$mt contextWindow=$cw"
}
if ($tokensIssues -eq 0) {
    $reportItems += "All maxTokens in valid range"
} else {
    $reportItems += "WARNING: $tokensIssues model(s) with maxTokens issues"
}

# Check 5: Alias mapping
Write-Log "INFO" "Checking alias mapping..."
$defaultModelsHash = @{}
$config.agents.defaults.models.PSObject.Properties | ForEach-Object {
    $defaultModelsHash[$_.Name] = $true
}
$missingAliases = 0
foreach ($modelId in $allModels) {
    $providerName = if ($dsModels.id -contains $modelId) { "dashscope-coding-plan" } else { "minimax-coding-plan" }
    $fullName = "$providerName/$modelId"
    if (-not $defaultModelsHash.ContainsKey($fullName)) {
        Write-Log "WARN" "  Missing alias: $fullName"
        $missingAliases++
    }
}
if ($missingAliases -eq 0) {
    $reportItems += "All 8 model aliases mapped"
} else {
    $reportItems += "WARNING: $missingAliases missing alias(es)"
}

# Check 6: Hooks
Write-Log "INFO" "Checking hooks..."
$enabledHooks = @()
$config.hooks.internal.entries.PSObject.Properties | ForEach-Object {
    if ($_.Value.enabled -eq $true) { $enabledHooks += $_.Name }
}
$recommendedHooks = @("session-memory", "command-logger", "boot-md")
$missingHooks = @()
foreach ($h in $recommendedHooks) {
    if ($h -notin $enabledHooks) { $missingHooks += $h }
}
if ($missingHooks.Count -eq 0) {
    $reportItems += "All recommended hooks enabled: $($recommendedHooks -join ', ')"
} else {
    $reportItems += "WARNING: Missing hooks: $($missingHooks -join ', ')"
}
Write-Log "INFO" "  Enabled hooks: $($enabledHooks -join ', ')"

# Check 7: Concurrency
Write-Log "INFO" "Checking concurrency..."
$maxC = $config.agents.defaults.maxConcurrent
$subC = $config.agents.defaults.subagents.maxConcurrent
Write-Log "INFO" "  maxConcurrent=$maxC subagents.maxConcurrent=$subC"
$reportItems += "Concurrency: agent=$maxC subagent=$subC"

# Check 8: Sensitive info
Write-Log "INFO" "Checking sensitive info..."
# Check for env var references (good) vs hardcoded values (bad)
$hasEnvVar = $configRaw -match '\$\{[A-Z_]+\}'
$hasUnredactedToken = ($configRaw -match 'token["\s:]+"[a-f0-9]{32,}"') -and ($configRaw -notmatch 'token["\s:]+"?\$\{')
$hasUnredactedApiKey = ($configRaw -match 'apiKey["\s:]+"sk-[a-zA-Z0-9]{20,}') -and ($configRaw -notmatch 'apiKey["\s:]+"?\$\{')
if ($hasEnvVar -and -not $hasUnredactedToken -and -not $hasUnredactedApiKey) {
    $reportItems += "Sensitive info properly using env vars"
} elseif ($hasEnvVar) {
    $reportItems += "WARNING: Some secrets may be hardcoded (not env var)"
} else {
    $reportItems += "WARNING: No env var references found"
}

# Save
if (-not $DryRun) {
    Write-Log "INFO" "Saving config..."
    $newJson = $config | ConvertTo-Json -Depth 20
    Set-Content -Path $ConfigPath -Value $newJson -Encoding UTF8
    
    $verify = Test-Path $ConfigPath
    if ($verify) {
        Write-Log "OK" "Config saved successfully"
        $needsRestart = ($autoChanges.Count -gt 0)
    } else {
        Write-Log "ERROR" "Config save failed"
    }
    
    # State file
    $state = @{
        lastRun = $timestamp
        runId = $runId
        autoChanges = $autoChanges
        reportItems = $reportItems
        success = $true
    } | ConvertTo-Json -Depth 5
    Set-Content -Path $StateFile -Value $state -Encoding UTF8
    
    # Log file
    $logEntry = "`n## $timestamp (Run: $runId)`n`n"
    $logEntry += "### Auto Changes`n"
    if ($autoChanges.Count -gt 0) {
        foreach ($c in $autoChanges) { $logEntry += "- $c`n" }
    } else {
        $logEntry += "- No auto changes`n"
    }
    $logEntry += "`n### Report`n"
    foreach ($r in $reportItems) { $logEntry += "- $r`n" }
    
    if (Test-Path $LogFile) {
        $existing = Get-Content $LogFile -Raw
        $logEntry = $existing + $logEntry
    }
    Set-Content -Path $LogFile -Value $logEntry -Encoding UTF8
} else {
    Write-Log "INFO" "[DryRun] Skipped file writes"
}

# Report
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Config Optimizer Report - $timestamp" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
if ($autoChanges.Count -gt 0) {
    Write-Host "[AUTO CHANGES] ($(if($DryRun){'preview'}else{'applied'})):" -ForegroundColor Green
    foreach ($c in $autoChanges) { Write-Host "  * $c" -ForegroundColor Green }
    Write-Host ""
}
Write-Host "[CHECK RESULTS]" -ForegroundColor Yellow
foreach ($r in $reportItems) { Write-Host "  $r" }
Write-Host ""
if ($needsRestart -and -not $DryRun) {
    Write-Host "NOTE: Gateway restart may be needed" -ForegroundColor Yellow
}
Write-Host "RunID: $runId | DryRun: $DryRun"

$summary = @{
    timestamp = $timestamp
    runId = $runId
    autoChangesCount = $autoChanges.Count
    autoChanges = $autoChanges
    reportItems = $reportItems
    needsRestart = $needsRestart
    dryRun = $DryRun
}
$summary | ConvertTo-Json
