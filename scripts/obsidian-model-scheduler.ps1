# Obsidian Model Scheduler
# Auto-select model for Obsidian note operations

param(
    [string]$Task,
    [string]$VaultPath = "E:\software\Obsidian\vault",
    [switch]$AnalyzeOnly,
    [switch]$Report
)

$ErrorActionPreference = "Continue"
$workspaceRoot = "D:\OpenClaw\.openclaw\workspace"
$statePath = Join-Path $workspaceRoot "memory\obsidian-model-state.json"
$logPath = Join-Path $workspaceRoot "memory\obsidian-model-log.md"

Write-Host ""
Write-Host "=== Obsidian Model Scheduler ===" -ForegroundColor Cyan
Write-Host "Run time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

# Model configuration for Obsidian
$MODEL_CONFIG = @{
    knowledge = @{
        model = "qwen3.5-plus"
        keywords = @("note", "Obsidian", "knowledge", "node", "link", "graph", "create", "extend", "concept")
        qualityCheck = @("title", "sections", "links", "overview", "keypoints", "metadata")
    }
    analysis = @{
        model = "glm-5"
        keywords = @("review", "summary", "analysis", "reason", "decision", "experience", "lesson", "improve")
        qualityCheck = @("reason", "suggestions", "data", "conclusion", "actionable")
    }
    structure = @{
        model = "qwen3-coder-plus"
        keywords = @("structure", "format", "markdown", "diagram", "Mermaid", "YAML", "normalize", "syntax")
        qualityCheck = @("syntax", "format", "no-errors", "ready-to-use")
    }
}

$DEFAULT_MODEL = "qwen3.5-plus"

# Initialize state
function Initialize-State {
    if (-not (Test-Path $statePath)) {
        $initialState = @{
            modelStats = @{
                "qwen3.5-plus" = @{ total = 0; success = 0; failure = 0; successRate = 1.0 }
                "glm-5" = @{ total = 0; success = 0; failure = 0; successRate = 1.0 }
                "qwen3-coder-plus" = @{ total = 0; success = 0; failure = 0; successRate = 1.0 }
            }
            taskTypeStats = @{
                knowledge = @{ total = 0; success = 0 }
                analysis = @{ total = 0; success = 0 }
                structure = @{ total = 0; success = 0 }
            }
            protectionStats = @{
                duplicatesDetected = 0
                notesMerged = 0
                orphansLinked = 0
                inboxProcessed = 0
            }
            lastUpdated = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        }
        $initialState | ConvertTo-Json -Depth 10 | Set-Content -Path $statePath -Encoding UTF8
        Write-Host "[INFO] State file initialized" -ForegroundColor Green
    }
}

function Get-State {
    if (Test-Path $statePath) {
        return Get-Content -Path $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    return $null
}

function Update-State {
    param(
        [string]$Model,
        [string]$TaskType,
        [bool]$Success
    )
    
    $state = Get-State
    if (-not $state) { return }
    
    if ($state.modelStats.$Model) {
        $state.modelStats.$Model.total++
        if ($Success) {
            $state.modelStats.$Model.success++
        } else {
            $state.modelStats.$Model.failure++
        }
        if ($state.modelStats.$Model.total -gt 0) {
            $state.modelStats.$Model.successRate = [math]::Round(
                $state.modelStats.$Model.success / $state.modelStats.$Model.total, 3
            )
        }
    }
    
    if ($TaskType -and $state.taskTypeStats.$TaskType) {
        $state.taskTypeStats.$TaskType.total++
        if ($Success) {
            $state.taskTypeStats.$TaskType.success++
        }
    }
    
    $state.lastUpdated = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    $state | ConvertTo-Json -Depth 10 | Set-Content -Path $statePath -Encoding UTF8
}

# Identify task type
function Identify-TaskType {
    param([string]$TaskText)
    
    Write-Host "[INFO] Analyzing task type" -ForegroundColor Gray
    
    $scores = @{
        knowledge = 0
        analysis = 0
        structure = 0
    }
    
    foreach ($type in $MODEL_CONFIG.Keys) {
        $config = $MODEL_CONFIG[$type]
        foreach ($keyword in $config.keywords) {
            if ($TaskText -match $keyword) {
                if ($keyword -match "^(Obsidian|Mermaid|YAML)$") {
                    $scores[$type] += 3
                } elseif ($keyword -match "^(note|review|summary|analysis|structure|format)$") {
                    $scores[$type] += 2
                } else {
                    $scores[$type] += 1
                }
            }
        }
    }
    
    $maxScore = 0
    $detectedType = "knowledge"
    
    foreach ($type in $scores.Keys) {
        if ($scores[$type] -gt $maxScore) {
            $maxScore = $scores[$type]
            $detectedType = $type
        }
    }
    
    Write-Host "[INFO] Result: $detectedType (score: $maxScore)" -ForegroundColor Gray
    return $detectedType
}

# Select model with fallback
function Select-Model {
    param(
        [string]$TaskType,
        [string]$CurrentModel,
        [int]$RetryCount = 0
    )
    
    if ($RetryCount -eq 0) {
        if ($MODEL_CONFIG[$TaskType]) {
            $selectedModel = $MODEL_CONFIG[$TaskType].model
            Write-Host "[SUCCESS] Selected model: $selectedModel (task type: $TaskType)" -ForegroundColor Green
            return $selectedModel
        }
        Write-Host "[WARNING] Unknown task type, using default: $DEFAULT_MODEL" -ForegroundColor Yellow
        return $DEFAULT_MODEL
    }
    
    # Fallback chain for Obsidian
    $fallbackChain = @{
        "qwen3.5-plus" = @("glm-5", "qwen3-coder-plus")
        "glm-5" = @("qwen3.5-plus", "qwen3-coder-plus")
        "qwen3-coder-plus" = @("qwen3.5-plus", "glm-5")
    }
    
    if ($fallbackChain[$CurrentModel]) {
        $fallbackIndex = $RetryCount - 1
        if ($fallbackIndex -lt $fallbackChain[$CurrentModel].Count) {
            $nextModel = $fallbackChain[$CurrentModel][$fallbackIndex]
            Write-Host "[WARNING] Retry $RetryCount, switching to: $nextModel" -ForegroundColor Yellow
            return $nextModel
        }
    }
    
    Write-Host "[ERROR] All retries failed, using fallback: qwen3-coder-plus" -ForegroundColor Red
    return "qwen3-coder-plus"
}

# Check for duplicate notes
function Test-DuplicateNote {
    param(
        [string]$Title,
        [string]$Vault
    )
    
    $inboxPath = Join-Path $Vault "00-Inbox"
    $knowledgePath = Join-Path $Vault "knowledge"
    
    # Check Inbox
    if (Test-Path $inboxPath) {
        $existing = Get-ChildItem -Path $inboxPath -Filter "*.md" | Where-Object {
            $_.BaseName -eq $Title
        }
        if ($existing) {
            Write-Host "[WARNING] Duplicate found in Inbox: $Title" -ForegroundColor Yellow
            return $true
        }
    }
    
    # Check knowledge directories
    if (Test-Path $knowledgePath) {
        $existing = Get-ChildItem -Path $knowledgePath -Recurse -Filter "*.md" | Where-Object {
            $_.BaseName -eq $Title
        }
        if ($existing) {
            Write-Host "[WARNING] Duplicate found in knowledge: $Title" -ForegroundColor Yellow
            return $true
        }
    }
    
    return $false
}

# Initialize
Initialize-State

# Analyze mode
if ($AnalyzeOnly) {
    if (-not $Task) {
        Write-Host "Error: Please provide task description (-Task parameter)" -ForegroundColor Red
        exit 1
    }
    
    $taskType = Identify-TaskType -TaskText $Task
    $model = $MODEL_CONFIG[$taskType].model
    
    Write-Host ""
    Write-Host "Analysis Result:" -ForegroundColor Yellow
    Write-Host "  Task Type: $taskType"
    Write-Host "  Recommended Model: $model"
    Write-Host "  Quality Checks: $($MODEL_CONFIG[$taskType].qualityCheck -join ', ')"
    Write-Host ""
    
    return @{
        taskType = $taskType
        model = $model
        qualityCheck = $MODEL_CONFIG[$taskType].qualityCheck
    }
}

# Report mode
if ($Report) {
    $state = Get-State
    
    Write-Host ""
    Write-Host "=== Obsidian Model Scheduler Status ===" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Model Statistics:" -ForegroundColor Yellow
    foreach ($model in $state.modelStats.PSObject.Properties.Name) {
        $stats = $state.modelStats.$model
        $rate = [math]::Round($stats.successRate * 100, 1)
        $color = if ($stats.successRate -ge 0.9) { "Green" }
                 elseif ($stats.successRate -ge 0.7) { "Yellow" }
                 else { "Red" }
        Write-Host "  $model : Success Rate $rate% ($($stats.success)/$($stats.total))" -ForegroundColor $color
    }
    
    Write-Host ""
    Write-Host "Task Type Statistics:" -ForegroundColor Yellow
    foreach ($type in $state.taskTypeStats.PSObject.Properties.Name) {
        $stats = $state.taskTypeStats.$type
        $rate = if ($stats.total -gt 0) { [math]::Round($stats.success / $stats.total * 100, 1) } else { 0 }
        Write-Host "  $type : Success Rate $rate% ($($stats.success)/$($stats.total))"
    }
    
    Write-Host ""
    Write-Host "Protection Stats:" -ForegroundColor Yellow
    Write-Host "  Duplicates Detected: $($state.protectionStats.duplicatesDetected)"
    Write-Host "  Notes Merged: $($state.protectionStats.notesMerged)"
    Write-Host "  Orphans Linked: $($state.protectionStats.orphansLinked)"
    Write-Host "  Inbox Processed: $($state.protectionStats.inboxProcessed)"
    
    Write-Host ""
    Write-Host "Last Updated: $($state.lastUpdated)" -ForegroundColor Gray
    Write-Host ""
    
    return $state
}

# No parameters - show help
if (-not $Task) {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\obsidian-model-scheduler.ps1 -Task `"task`" -AnalyzeOnly  # Analyze only"
    Write-Host "  .\obsidian-model-scheduler.ps1 -Report                      # View report"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\obsidian-model-scheduler.ps1 -AnalyzeOnly -Task `"Create Obsidian note about AI`""
    Write-Host "  .\obsidian-model-scheduler.ps1 -AnalyzeOnly -Task `"Review weekly progress`""
    Write-Host "  .\obsidian-model-scheduler.ps1 -AnalyzeOnly -Task `"Fix Markdown format`""
    Write-Host ""
}
