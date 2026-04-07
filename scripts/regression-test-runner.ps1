$ErrorActionPreference = "SilentlyContinue"
$results = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    tests = @()
    passed = 0
    failed = 0
    warnings = 0
}

# --- T001: JSON Syntax Validation ---
Write-Host "[T001] JSON Syntax Validation..."
$t001 = @{ name="T001"; desc="JSON Syntax Validation"; status="PASS"; details=@() }
try {
    $jsonFiles = @("D:\OpenClaw\.openclaw\workspace\openclaw.json", "D:\OpenClaw\.openclaw\workspace\cron\jobs.json")
    foreach ($f in $jsonFiles) {
        if (Test-Path $f) {
            Get-Content $f -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop | Out-Null
            $t001.details += "OK: $(Split-Path $f -Leaf)"
        }
    }
    $results.passed++
} catch {
    $t001.status = "FAIL"
    $t001.error = $_.Exception.Message
    $results.failed++
}
$results.tests += $t001

# --- T002: Model Name Validation ---
Write-Host "[T002] Model Name Validation..."
$t002 = @{ name="T002"; desc="Model Name Validation"; status="PASS"; details=@(); errors=@() }
$validModels = @(
    "dashscope-coding-plan/qwen3.5-plus",
    "dashscope-coding-plan/qwen3-coder-plus",
    "dashscope-coding-plan/qwen3-coder-next",
    "dashscope-coding-plan/glm-5",
    "dashscope-coding-plan/glm-4.7",
    "dashscope-coding-plan/kimi-k2.5",
    "dashscope-coding-plan/minimax-m2.5",
    "minimax-coding-plan/minimax-2.7"
)
try {
    $cronData = Get-Content "D:\OpenClaw\.openclaw\workspace\cron\jobs.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($job in $cronData.jobs) {
        if ($job.payload.model) {
            $model = $job.payload.model
            if ($model -notin $validModels) {
                $t002.status = "FAIL"
                $t002.errors += "Job '$($job.name)' uses invalid model: $model"
            } else {
                $t002.details += "OK: $($job.name) -> $model"
            }
        }
    }
    if ($t002.status -eq "PASS") { $results.passed++ }
    else { $results.failed++ }
} catch {
    $t002.status = "FAIL"
    $t002.error = $_.Exception.Message
    $results.failed++
}
$results.tests += $t002

# --- T003: Cron Expression Validation ---
Write-Host "[T003] Cron Expression Validation..."
$t003 = @{ name="T003"; desc="Cron Expression Validation"; status="PASS"; details=@(); errors=@() }
try {
    $cronData = Get-Content "D:\OpenClaw\.openclaw\workspace\cron\jobs.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($job in $cronData.jobs) {
        if ($job.schedule.expr) {
            $parts = $job.schedule.expr -split "\s+"
            if ($parts.Count -lt 5 -or $parts.Count -gt 6) {
                $t003.status = "FAIL"
                $t003.errors += "Job '$($job.name)' has invalid cron parts: $($job.schedule.expr)"
            } else {
                $t003.details += "OK: $($job.name) -> $($job.schedule.expr)"
            }
        }
    }
    if ($t003.status -eq "PASS") { $results.passed++ }
    else { $results.failed++ }
} catch {
    $t003.status = "FAIL"
    $t003.error = $_.Exception.Message
    $results.failed++
}
$results.tests += $t003

# --- T004: Gateway Health Check ---
Write-Host "[T004] Gateway Health Check..."
$t004 = @{ name="T004"; desc="Gateway Health Check"; status="PASS"; details=@() }
try {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $resp = Invoke-WebRequest -Uri "http://127.0.0.1:18789/openclaw/" -TimeoutSec 5 -UseBasicParsing
    $sw.Stop()
    $statusCode = $resp.StatusCode
    if ($statusCode -eq 200) {
        $t004.details += "HTTP 200 in $($sw.ElapsedMilliseconds)ms"
        $results.passed++
    } else {
        $t004.status = "FAIL"
        $t004.details += "HTTP $statusCode"
        $results.failed++
    }
} catch {
    $t004.status = "FAIL"
    $t004.error = $_.Exception.Message
    $results.failed++
}
$results.tests += $t004

# --- T005: PowerShell Syntax Check ---
Write-Host "[T005] PowerShell Syntax Check..."
$t005 = @{ name="T005"; desc="PowerShell Syntax Check"; status="PASS"; details=@(); errors=@() }
try {
    $psFiles = Get-ChildItem "D:\OpenClaw\.openclaw\workspace\scripts\*.ps1" -ErrorAction SilentlyContinue
    foreach ($f in $psFiles) {
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $f.FullName -Raw), [ref]$errors)
        if ($errors.Count -eq 0) {
            $t005.details += "OK: $($f.Name)"
        } else {
            $t005.status = "WARN"
            $t005.errors += "$($f.Name): $($errors.Count) syntax issue(s)"
        }
    }
    if ($t005.status -eq "PASS") { $results.passed++ }
    else { $results.warnings++ }
} catch {
    $t005.status = "WARN"
    $t005.error = $_.Exception.Message
    $results.warnings++
}
$results.tests += $t005

# Save results
$results | ConvertTo-Json -Depth 5 | Out-File "D:\OpenClaw\.openclaw\workspace\memory\test-runner-state.json" -Encoding UTF8

# Summary
Write-Host ""
Write-Host "=== TEST SUMMARY ==="
Write-Host "Passed: $($results.passed)/$($results.tests.Count)"
Write-Host "Failed: $($results.failed)"
Write-Host "Warnings: $($results.warnings)"
Write-Host ""

# Print failures
foreach ($t in $results.tests) {
    if ($t.status -ne "PASS") {
        Write-Host "[$($t.status)] $($t.name): $($t.desc)"
        if ($t.errors) {
            foreach ($e in $t.errors) { Write-Host "  ERROR: $e" }
        }
        if ($t.error) {
            Write-Host "  ERROR: $($t.error)"
        }
    }
}

# Output full JSON
$results | ConvertTo-Json -Depth 5
