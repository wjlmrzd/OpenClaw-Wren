# Regression Test Runner for OpenClaw
# Executes core tests after detecting configuration/code changes

param(
    [switch]$AnalyzeOnly,
    [switch]$Report
)

# Define test constants
$TEST_CASES = @{
    "T001" = "JSON Syntax Validation"
    "T002" = "Model Name Validation"
    "T003" = "Cron Expression Validation"
    "T004" = "Gateway Health Check"
    "T005" = "PowerShell Syntax Check"
}

# Define valid models
$VALID_MODELS = @(
    "dashscope-coding-plan/qwen3.5-plus",
    "dashscope-coding-plan/qwen3-coder-plus", 
    "dashscope-coding-plan/qwen3-coder-next",
    "dashscope-coding-plan/glm-5",
    "dashscope-coding-plan/glm-4.7",
    "dashscope-coding-plan/kimi-k2.5",
    "dashscope-coding-plan/minimax-m2.5"
)

# Define monitored files
$MONITORED_FILES = @(
    "openclaw.json",
    "cron/jobs.json",
    "agents/main/openclaw.json"
)

# Find all PowerShell scripts in scripts directory
$PS_SCRIPTS = Get-ChildItem -Path "scripts" -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue

# Test result tracking
$RESULTS = @{}

function Get-FileHashCache {
    $hashCache = @{}
    foreach ($file in $MONITORED_FILES) {
        if (Test-Path $file) {
            $content = Get-Content $file -Raw
            $hash = (Get-FileHash -Path $file -Algorithm SHA256).Hash
            $hashCache[$file] = $hash
        }
    }
    
    # Also track PowerShell scripts
    foreach ($script in $PS_SCRIPTS) {
        $hash = (Get-FileHash -Path $script.FullName -Algorithm SHA256).Hash
        $hashCache[$script.FullName] = $hash
    }
    
    return $hashCache
}

function Compare-FileHashes {
    param([hashtable]$OldHashes, [hashtable]$NewHashes)
    
    $changedFiles = @()
    
    foreach ($file in $OldHashes.Keys) {
        if ($null -eq $NewHashes[$file] -or $OldHashes[$file] -ne $NewHashes[$file]) {
            $changedFiles += $file
        }
    }
    
    foreach ($file in $NewHashes.Keys) {
        if ($null -eq $OldHashes[$file]) {
            $changedFiles += $file
        }
    }
    
    return $changedFiles
}

function Backup-Configuration {
    $backupDir = "memory/test-backups"
    if (!(Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupName = "$backupDir/config-backup-$timestamp"
    New-Item -ItemType Directory -Path $backupName -Force
    
    foreach ($file in $MONITORED_FILES) {
        if (Test-Path $file) {
            Copy-Item $file "$backupName/$($file.Replace('/', '-'))" -Force
        }
    }
    
    Write-Output "Configuration backed up to: $backupName"
}

function Test-JsonSyntax {
    Write-Output "Running T001 - JSON Syntax Validation..."
    
    try {
        $filesToCheck = @("openclaw.json", "cron/jobs.json", "agents/main/openclaw.json")
        
        foreach ($file in $filesToCheck) {
            if (Test-Path $file) {
                $content = Get-Content $file -Raw
                $null = ConvertFrom-Json $content
            }
        }
        
        $RESULTS["T001"] = @{Status = "PASS"; Message = "All JSON files parsed successfully"}
        Write-Output "T001: PASS"
    }
    catch {
        $RESULTS["T001"] = @{Status = "FAIL"; Message = "JSON syntax error: $($_.Exception.Message)"}
        Write-Output "T001: FAIL - $($_.Exception.Message)"
    }
}

function Test-ModelNames {
    Write-Output "Running T002 - Model Name Validation..."
    
    try {
        $configFiles = @("openclaw.json", "cron/jobs.json", "agents/main/openclaw.json")
        $invalidModels = @()
        
        foreach ($file in $configFiles) {
            if (Test-Path $file) {
                $content = Get-Content $file -Raw
                $json = ConvertFrom-Json $content
                
                # Look for model references in the JSON structure
                $modelsFound = Find-ModelReferences -JsonObject $json -Path $file
                foreach ($model in $modelsFound) {
                    if ($VALID_MODELS -notcontains $model) {
                        $invalidModels += @{Model = $model; File = $file}
                    }
                }
            }
        }
        
        if ($invalidModels.Count -eq 0) {
            $RESULTS["T002"] = @{Status = "PASS"; Message = "All model names are valid"}
            Write-Output "T002: PASS"
        }
        else {
            $errorDetails = $invalidModels | ForEach-Object { "Invalid model '$($_.Model)' in $($_.File)" }
            $RESULTS["T002"] = @{Status = "FAIL"; Message = ($errorDetails -join "; ")}
            Write-Output "T002: FAIL - $($errorDetails -join "; ")"
        }
    }
    catch {
        $RESULTS["T002"] = @{Status = "FAIL"; Message = "Error checking model names: $($_.Exception.Message)"}
        Write-Output "T002: FAIL - Error: $($_.Exception.Message)"
    }
}

function Find-ModelReferences {
    param($JsonObject, $Path, $Accumulator = @())
    
    if ($JsonObject -is [System.Collections.IDictionary]) {
        foreach ($key in $JsonObject.Keys) {
            $value = $JsonObject[$key]
            
            if ($key -eq "model" -or $key -eq "primary" -or $key -eq "models") {
                if ($value -is [string] -and $value -match "^[\w\-\/]+$") {
                    $Accumulator += $value
                }
                elseif ($value -is [System.Collections.IList]) {
                    foreach ($item in $value) {
                        if ($item -is [string]) {
                            $Accumulator += $item
                        }
                    }
                }
            }
            
            if ($value -is [System.Collections.IDictionary] -or $value -is [System.Collections.IList]) {
                Find-ModelReferences -JsonObject $value -Path $Path -Accumulator $Accumulator
            }
        }
    }
    elseif ($JsonObject -is [System.Collections.IList]) {
        foreach ($item in $JsonObject) {
            if ($item -is [System.Collections.IDictionary] -or $item -is [System.Collections.IList]) {
                Find-ModelReferences -JsonObject $item -Path $Path -Accumulator $Accumulator
            }
        }
    }
    
    return $Accumulator
}

function Test-CronExpressions {
    Write-Output "Running T003 - Cron Expression Validation..."
    
    try {
        if (Test-Path "cron/jobs.json") {
            $content = Get-Content "cron/jobs.json" -Raw
            $json = ConvertFrom-Json $content
            
            $invalidExpressions = @()
            
            if ($json.jobs) {
                foreach ($job in $json.jobs) {
                    if ($job.schedule -and $job.schedule.expr) {
                        $expr = $job.schedule.expr
                        $parts = $expr.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)
                        
                        # Basic validation: should have 5-6 parts
                        if ($parts.Length -lt 5 -or $parts.Length -gt 6) {
                            $invalidExpressions += @{Expression = $expr; Job = $job.name}
                        }
                    }
                }
            }
            
            if ($invalidExpressions.Count -eq 0) {
                $RESULTS["T003"] = @{Status = "PASS"; Message = "All cron expressions are valid"}
                Write-Output "T003: PASS"
            }
            else {
                $errorDetails = $invalidExpressions | ForEach-Object { "Invalid cron '$($_.Expression)' in job '$($_.Job)'" }
                $RESULTS["T003"] = @{Status = "FAIL"; Message = ($errorDetails -join "; ")}
                Write-Output "T003: FAIL - $($errorDetails -join "; ")"
            }
        }
        else {
            $RESULTS["T003"] = @{Status = "PASS"; Message = "No cron jobs file to validate"}
            Write-Output "T003: PASS (no cron file)"
        }
    }
    catch {
        $RESULTS["T003"] = @{Status = "FAIL"; Message = "Error checking cron expressions: $($_.Exception.Message)"}
        Write-Output "T003: FAIL - Error: $($_.Exception.Message)"
    }
}

function Test-GatewayHealth {
    Write-Output "Running T004 - Gateway Health Check..."
    
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        # Try to access the gateway health endpoint
        $response = Invoke-RestMethod -Uri "http://127.0.0.1:18789/openclaw/" -TimeoutSec 10 -ErrorAction Stop
        
        $stopwatch.Stop()
        $responseTime = $stopwatch.ElapsedMilliseconds
        
        if ($responseTime -gt 5000) {
            $RESULTS["T004"] = @{Status = "FAIL"; Message = "Gateway response too slow: ${responseTime}ms (>5000ms)"}
            Write-Output "T004: FAIL - Response time: ${responseTime}ms"
        }
        else {
            $RESULTS["T004"] = @{Status = "PASS"; Message = "Gateway healthy, response time: ${responseTime}ms"}
            Write-Output "T004: PASS - Response time: ${responseTime}ms"
        }
    }
    catch {
        $RESULTS["T004"] = @{Status = "FAIL"; Message = "Gateway unhealthy: $($_.Exception.Message)"}
        Write-Output "T004: FAIL - Gateway error: $($_.Exception.Message)"
    }
}

function Test-PowerShellSyntax {
    Write-Output "Running T005 - PowerShell Syntax Check..."
    
    try {
        $syntaxErrors = @()
        
        foreach ($script in $PS_SCRIPTS) {
            try {
                $contents = Get-Content $script.FullName -Raw
                $errors = $null
                $null = [System.Management.Automation.PSParser]::Tokenize($contents, [ref]$errors)
                
                if ($errors.Count -gt 0) {
                    $errorList = $errors | ForEach-Object { "Line $($_.StartLine): $($_.Content) - $($_.Message)" }
                    $syntaxErrors += @{Script = $script.Name; Errors = $errorList}
                }
            }
            catch {
                $syntaxErrors += @{Script = $script.Name; Errors = @("Parse error: $($_.Exception.Message)"})
            }
        }
        
        if ($syntaxErrors.Count -eq 0) {
            $RESULTS["T005"] = @{Status = "PASS"; Message = "All PowerShell scripts have valid syntax"}
            Write-Output "T005: PASS"
        }
        else {
            $errorDetails = $syntaxErrors | ForEach-Object { "$($_.Script): $($_.Errors -join '; ')" }
            $RESULTS["T005"] = @{Status = "FAIL"; Message = ($errorDetails -join " | ")}
            Write-Output "T005: FAIL - $($errorDetails -join " | ")"
        }
    }
    catch {
        $RESULTS["T005"] = @{Status = "FAIL"; Message = "Error checking PowerShell syntax: $($_.Exception.Message)"}
        Write-Output "T005: FAIL - Error: $($_.Exception.Message)"
    }
}

function Generate-TestReport {
    $timestamp = Get-Date -Format "yyyy-MM-dd-HH:mm"
    $totalTests = $TEST_CASES.Count
    $passedTests = ($RESULTS.Values | Where-Object { $_.Status -eq "PASS" }).Count
    $failedTests = $totalTests - $passedTests
    
    $reportContent = @"
# Regression Test Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Summary
- Total Tests: $totalTests
- Passed: $passedTests
- Failed: $failedTests

## Results
"@
    
    foreach ($testId in $TEST_CASES.Keys | Sort-Object) {
        $result = $RESULTS[$testId]
        $statusIcon = if ($result.Status -eq "PASS") { "✅" } else { "❌" }
        $reportContent += "`n**${statusIcon} ${testId} - $($TEST_CASES[$testId])**: $($result.Status)`n"
        if ($result.Message) {
            $reportContent += "- Details: $($result.Message)`n"
        }
    }
    
    # Create reports directory if it doesn't exist
    $reportsDir = "memory/test-reports"
    if (!(Test-Path $reportsDir)) {
        New-Item -ItemType Directory -Path $reportsDir -Force
    }
    
    $reportFileName = "$(Get-Date -Format 'yyyy-MM-dd-HHmmss')-regression-test-report.md"
    $reportPath = Join-Path $reportsDir $reportFileName
    
    Set-Content -Path $reportPath -Value $reportContent -Encoding UTF8
    
    return $reportPath
}

function Get-IsSilentHour {
    $currentHour = (Get-Date).Hour
    return ($currentHour -ge 22 -or $currentHour -lt 6)
}

function Send-FailureNotification {
    param($FailedTests)
    
    $timestamp = Get-Date -Format "HH:mm"
    $notification = "🧪 回归测试报告 - $timestamp`n`n"
    $notification += "❌ 发现失败 ($($FailedTests.Count)/5 测试)`n`n"
    
    # Separate blocking and warning issues
    $blockingIssues = $FailedTests | Where-Object { $_.TestId -match "^(T001|T002|T003|T004)$" }
    $warningIssues = $FailedTests | Where-Object { $_.TestId -eq "T005" }
    
    if ($blockingIssues) {
        $notification += "**🔴 阻断性问题:**`n"
        for ($i = 0; $i -lt $blockingIssues.Count; $i++) {
            $issue = $blockingIssues[$i]
            $notification += "$($i + 1). $($issue.TestId) - $($TEST_CASES[$($issue.TestId)])`n"
            $notification += "   错误：$($issue.Message)`n"
        }
        $notification += "`n"
    }
    
    if ($warningIssues) {
        $notification += "**🟡 警告问题:**`n"
        for ($i = 0; $i -lt $warningIssues.Count; $i++) {
            $issue = $warningIssues[$i]
            $notification += "$($i + 1). $($issue.TestId) - $($TEST_CASES[$($issue.TestId)])`n"
            $notification += "   错误：$($issue.Message)`n"
        }
        $notification += "`n"
    }
    
    $notification += "**🔧 建议动作:**`n"
    $notification += "1. 检查上述错误并修复`n"
    $notification += "2. 重新运行测试确保问题已解决`n`n"
    
    $reportPath = Get-ChildItem "memory/test-reports" | Sort-Object CreationTime -Descending | Select-Object -First 1
    if ($reportPath) {
        $notification += "**📋 详情：**memory/test-reports/$($reportPath.Name)"
    }
    
    # In a real implementation, this would send to Telegram
    # For now we'll just output it
    Write-Output "NOTIFICATION TO SEND:"
    Write-Output $notification
}

# Main execution logic
Write-Output "🧪 OpenClaw Regression Test Runner"
Write-Output "Starting tests at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# Get initial file hashes to detect changes
$currentHashes = Get-FileHashCache
$previousHashesPath = "memory/test-runner-state.json"

$shouldRunTests = $true
$previousHashes = @{}

# Load previous hashes if they exist
if (Test-Path $previousHashesPath) {
    try {
        $stateContent = Get-Content $previousHashesPath -Raw | ConvertFrom-Json
        $previousHashes = @{}
        if ($stateContent.fileHashes) {
            foreach ($prop in $stateContent.fileHashes.PSObject.Properties) {
                $previousHashes[$prop.Name] = $prop.Value
            }
        }
        
        # Check if files have changed
        $changedFiles = Compare-FileHashes -OldHashes $previousHashes -NewHashes $currentHashes
        
        if ($changedFiles.Count -eq 0) {
            Write-Output "No changes detected, skipping tests"
            $shouldRunTests = $false
        }
        else {
            Write-Output "Changes detected in: $($changedFiles -join ", ")"
            Backup-Configuration
        }
    }
    catch {
        Write-Output "Could not load previous state, running tests anyway: $($_.Exception.Message)"
    }
}
else {
    Write-Output "No previous state found, running initial tests"
    Backup-Configuration
}

if ($shouldRunTests) {
    # Execute all tests
    Test-JsonSyntax
    Test-ModelNames
    Test-CronExpressions
    Test-GatewayHealth
    Test-PowerShellSyntax
    
    # Generate report
    $reportPath = Generate-TestReport
    
    # Determine if there are failures
    $failedTests = @()
    foreach ($testId in $RESULTS.Keys) {
        if ($RESULTS[$testId].Status -eq "FAIL") {
            $failedTests += @{TestId = $testId; Message = $RESULTS[$testId].Message}
        }
    }
    
    # Update state file with current hashes
    $state = @{
        lastRun = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        fileHashes = $currentHashes
        results = $RESULTS
    }
    
    $state | ConvertTo-Json -Depth 10 | Set-Content $previousHashesPath
    
    # Handle failures
    if ($failedTests.Count -gt 0) {
        Write-Output "Some tests failed, preparing notification..."
        
        # Check if we're in silent hours and if there are blocking issues
        $isSilentHour = Get-IsSilentHour
        $hasBlockingIssue = $failedTests | Where-Object { $_.TestId -match "^(T001|T002|T003|T004)$" }
        
        # Send notification if not in silent hours or if there's a blocking issue during silent hours
        if (!$isSilentHour -or $hasBlockingIssue) {
            Send-FailureNotification -FailedTests $failedTests
        }
        else {
            Write-Output "In silent hour with only warnings, deferring notification to morning summary"
        }
    }
    else {
        Write-Output "All tests passed!"
    }
}
else {
    Write-Output "Tests skipped due to no changes detected."
}

Write-Output "Regression test run completed."