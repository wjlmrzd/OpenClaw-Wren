# Knowledge Organizer for Obsidian
# Scan 00-Inbox, classify notes, move to proper directories, create links
#
# ══════════════════════════════════════════════════════════════
# 📋 整理规范 (整理要求)
# ══════════════════════════════════════════════════════════════
#
# 1. 触发写入规则
#    - Wren 要求写入笔记到知识库 → 统一先进入 00-Inbox/
#    - 由知识整理员（Cron）负责从 Inbox 归档到正式目录
#
# 2. 禁止行为
#    - 禁止直接将笔记写入正式目录（绕过 Inbox）
#    - 禁止创建重复主题文件
#    - 孤立笔记必须补充关联
#
# 3. 知识库保护机制
#    - 相似笔记必须合并
#    - 新笔记先进入 00-Inbox
#    - 知识整理员 Cron 每天 02:00 归档
#
# ══════════════════════════════════════════════════════════════

param(
    [string]$VaultPath = "E:\software\Obsidian\vault",
    [switch]$Report
)

$ErrorActionPreference = "Continue"
$workspaceRoot = "D:\OpenClaw\.openclaw\workspace"
$schedulerPath = Join-Path $workspaceRoot "scripts\obsidian-model-scheduler.ps1"
$logPath = Join-Path $workspaceRoot "memory\obsidian-model-log.md"
$statePath = Join-Path $workspaceRoot "memory\obsidian-model-state.json"

Write-Host ""
Write-Host "=== Obsidian Knowledge Organizer ===" -ForegroundColor Cyan
Write-Host "Run time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Vault: $VaultPath"
Write-Host ""

# Directories
$inboxPath = Join-Path $VaultPath "00-Inbox"
$knowledgePath = Join-Path $VaultPath "knowledge"
$knowledgeKnowledge = Join-Path $knowledgePath "知识"
$knowledgeProjects = Join-Path $knowledgePath "项目"
$knowledgeIssues = Join-Path $knowledgePath "问题"
$knowledgeSystem = Join-Path $knowledgePath "系统设计"

# Ensure directories exist
foreach ($dir in @($inboxPath, $knowledgePath, $knowledgeKnowledge, $knowledgeProjects, $knowledgeIssues, $knowledgeSystem)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        Write-Host "[INFO] Created: $dir" -ForegroundColor Gray
    }
}

# Initialize counters
$stats = @{
    inboxScanned = 0
    notesMoved = 0
    linksCreated = 0
    duplicatesDetected = 0
    orphansFound = 0
    errors = 0
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host $logEntry -ForegroundColor $color
    
    # Append to log file
    $logMarkdown = "- **$timestamp** [$Level] $Message`n"
    if (Test-Path $logPath) {
        $logMarkdown | Add-Content -Path $logPath -Encoding UTF8
    } else {
        "# Obsidian Model Log`n`n" | Set-Content -Path $logPath -Encoding UTF8
        $logMarkdown | Add-Content -Path $logPath -Encoding UTF8
    }
}

# Step 1: Scan Inbox
Write-Host "[1/5] Scanning 00-Inbox..." -ForegroundColor Yellow

if (Test-Path $inboxPath) {
    $inboxFiles = Get-ChildItem -Path $inboxPath -Filter "*.md" -File
    $stats.inboxScanned = $inboxFiles.Count
    Write-Host "  Found $($stats.inboxScanned) notes in Inbox" -ForegroundColor Green
} else {
    Write-Host "  Inbox not found" -ForegroundColor Red
    $stats.errors++
}

# Step 2: Classify and move notes
Write-Host "[2/5] Classifying and moving notes..." -ForegroundColor Yellow

foreach ($file in $inboxFiles) {
    try {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        
        # Determine category based on content
        $targetDir = $knowledgeKnowledge  # Default
        
        if ($content -match "type:\s*(project|项目)") {
            $targetDir = $knowledgeProjects
            Write-Log "Classified as project: $($file.Name)" "INFO"
        }
        elseif ($content -match "type:\s*(issue|问题)") {
            $targetDir = $knowledgeIssues
            Write-Log "Classified as issue: $($file.Name)" "INFO"
        }
        elseif ($content -match "type:\s*(system|design|系统 | 设计)") {
            $targetDir = $knowledgeSystem
            Write-Log "Classified as system: $($file.Name)" "INFO"
        }
        else {
            Write-Log "Classified as knowledge: $($file.Name)" "INFO"
        }
        
        # Check for duplicates
        $targetPath = Join-Path $targetDir $file.Name
        if (Test-Path $targetPath) {
            Write-Log "Duplicate detected: $($file.Name) - skipping" "WARNING"
            $stats.duplicatesDetected++
            continue
        }
        
        # Move file
        Move-Item -Path $file.FullName -Destination $targetPath -Force
        $stats.notesMoved++
        Write-Log "Moved: $($file.Name) -> $targetDir" "SUCCESS"
        
    } catch {
        Write-Log "Error processing $($file.Name): $_" "ERROR"
        $stats.errors++
    }
}

Write-Host "  Moved $($stats.notesMoved) notes" -ForegroundColor Green

# Step 3: Analyze notes for links (using scheduler)
Write-Host "[3/5] Analyzing notes for link opportunities..." -ForegroundColor Yellow

$allNotes = @()
foreach ($dir in @($knowledgeKnowledge, $knowledgeProjects, $knowledgeIssues, $knowledgeSystem)) {
    if (Test-Path $dir) {
        $allNotes += Get-ChildItem -Path $dir -Filter "*.md" -File
    }
}

Write-Host "  Total notes in knowledge base: $($allNotes.Count)" -ForegroundColor Gray

# Extract titles from all notes
$noteTitles = @{}
foreach ($note in $allNotes) {
    $content = Get-Content -Path $note.FullName -Raw -Encoding UTF8
    if ($content -match "^#\s+(.+)") {
        $title = $matches[1].Trim()
        $noteTitles[$title] = $note.FullName
    } else {
        $title = $note.BaseName
        $noteTitles[$title] = $note.FullName
    }
}

# Check for orphaned notes (no links)
$orphans = @()
foreach ($note in $allNotes) {
    $content = Get-Content -Path $note.FullName -Raw -Encoding UTF8
    if ($content -notmatch "\[\[.*?\]\]") {
        $orphans += $note
        $stats.orphansFound++
    }
}

Write-Host "  Found $($stats.orphansFound) orphaned notes (no links)" -ForegroundColor Yellow

# Step 4: Suggest links for orphaned notes
Write-Host "[4/5] Suggesting links for orphaned notes..." -ForegroundColor Yellow

$linksCreated = 0
foreach ($orphan in $orphans) {
    try {
        $content = Get-Content -Path $orphan.FullName -Raw -Encoding UTF8
        $suggestedLinks = @()
        
        # Find potential links by matching titles in content
        foreach ($title in $noteTitles.Keys) {
            if ($title -ne $orphan.BaseName -and $content -match [regex]::Escape($title)) {
                $suggestedLinks += $title
            }
        }
        
        # If suggestions found, update note
        if ($suggestedLinks.Count -gt 0) {
            $linkMarkdown = "`n## 关联`n"
            foreach ($link in $suggestedLinks | Select-Object -First 5) {
                $linkMarkdown += "- [[$link]]`n"
                $linksCreated++
            }
            
            # Append links to note
            $content += $linkMarkdown
            Set-Content -Path $orphan.FullName -Value $content -Encoding UTF8
            Write-Log "Added $($suggestedLinks.Count) links to: $($orphan.Name)" "SUCCESS"
        }
        
        $stats.linksCreated += $linksCreated
        
    } catch {
        Write-Log "Error processing orphan $($orphan.Name): $_" "ERROR"
        $stats.errors++
    }
}

Write-Host "  Created $linksCreated link suggestions" -ForegroundColor Green

# Step 5: Update state and generate report
Write-Host "[5/5] Generating report..." -ForegroundColor Yellow

# Update state file
if (Test-Path $statePath) {
    $state = Get-Content -Path $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $state.protectionStats.inboxProcessed += $stats.inboxScanned
    $state.protectionStats.duplicatesDetected += $stats.duplicatesDetected
    $state.protectionStats.orphansLinked += $linksCreated
    $state.lastUpdated = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    $state | ConvertTo-Json -Depth 10 | Set-Content -Path $statePath -Encoding UTF8
}

# Generate report
$reportDate = Get-Date -Format "yyyy-MM-dd"
$reportTime = Get-Date -Format "HH:mm:ss"
$report = @"
# Knowledge Organizer Report

**Date**: $reportDate $reportTime
**Vault**: $VaultPath

## Summary

| Metric | Count |
|--------|-------|
| Inbox Scanned | $($stats.inboxScanned) |
| Notes Moved | $($stats.notesMoved) |
| Links Created | $($stats.linksCreated) |
| Duplicates Detected | $($stats.duplicatesDetected) |
| Orphans Found | $($stats.orphansFound) |
| Errors | $($stats.errors) |

## Status

"@

$statusLine = ""
if ($stats.errors -eq 0) {
    $statusLine = "All operations completed successfully"
} else {
    $statusLine = "Completed with $($stats.errors) error(s)"
}

$report += "`n$statusLine`n"
$report += "`n---`n"

# Save report
$reportPath = Join-Path $workspaceRoot "memory\knowledge-organizer-report-$(Get-Date -Format 'yyyy-MM-dd').md"
$report | Set-Content -Path $reportPath -Encoding UTF8

# Output report
Write-Host ""
Write-Host "=== Knowledge Organizer Report ===" -ForegroundColor Cyan
Write-Host $report
Write-Host ""
Write-Host "Report saved to: $reportPath" -ForegroundColor Green

# Return stats
return $stats
