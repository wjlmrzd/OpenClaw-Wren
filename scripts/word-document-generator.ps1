# -*- coding: utf-8 -*-
<#
.SYNOPSIS
    Word Document Generator - PowerShell wrapper for word_generator.py
    
.DESCRIPTION
    Create, edit, and extract content from Word documents using python-docx
    
.PARAMETER Action
    Action to perform: create, edit, extract, add-paragraph, add-table, set-style
    
.PARAMETER Input
    Input file path (existing document)
    
.PARAMETER Output
    Output file path
    
.PARAMETER Template
    Template file path for creating new documents
    
.PARAMETER Title
    Document title (for create action)
    
.PARAMETER Text
    Text content (for add-paragraph, add-heading actions)
    
.PARAMETER Find
    Text to find (for edit action)
    
.PARAMETER Replace
    Text to replace (for edit action)
    
.PARAMETER Style
    Paragraph style name
    
.PARAMETER Level
    Heading level (1-9)
    
.PARAMETER Headers
    Table headers (space-separated)
    
.PARAMETER Data
    Table data rows (space-separated, use comma within row)
    
.EXAMPLE
    .\word-document-generator.ps1 -Action create -Title "My Report" -Output "report.docx"
    .\word-document-generator.ps1 -Action edit -Input "doc.docx" -Find "OLD" -Replace "NEW"
    .\word-document-generator.ps1 -Action extract -Input "doc.docx" -Output "content.txt"
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("create", "edit", "extract", "add-paragraph", "add-heading", "add-table", "set-style")]
    [string]$Action,
    
    [Parameter()]
    [string]$Input,
    
    [Parameter()]
    [string]$Output,
    
    [Parameter()]
    [string]$Template,
    
    [Parameter()]
    [string]$Title,
    
    [Parameter()]
    [string]$Text,
    
    [Parameter()]
    [string]$Find,
    
    [Parameter()]
    [string]$Replace,
    
    [Parameter()]
    [string]$Style = "Normal",
    
    [Parameter()]
    [int]$Level = 1,
    
    [Parameter()]
    [string[]]$Headers,
    
    [Parameter()]
    [string[]]$Data,
    
    [Parameter()]
    [switch]$Bold,
    
    [Parameter()]
    [switch]$Italic,
    
    [Parameter()]
    [string]$Align = "left"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PythonScript = Join-Path $ScriptDir "word_generator.py"

# Check Python script exists
if (-not (Test-Path $PythonScript)) {
    Write-Error "Python script not found: $PythonScript"
    exit 1
}

# Build arguments
$pyArgs = @($Action)

switch ($Action) {
    "create" {
        if ($Title) { $pyArgs += "--title"; $pyArgs += $Title }
        if ($Output) { $pyArgs += "--output"; $pyArgs += $Output } else { $pyArgs += "--output"; $pyArgs += "output.docx" }
        if ($Template) { $pyArgs += "--template"; $pyArgs += $Template }
    }
    "edit" {
        if (-not $Input) { Write-Error "Input file required for edit action"; exit 1 }
        if (-not $Find) { Write-Error "Find text required for edit action"; exit 1 }
        $pyArgs += "--input"; $pyArgs += $Input
        $pyArgs += "--find"; $pyArgs += $Find
        if ($Replace) { $pyArgs += "--replace"; $pyArgs += $Replace }
        if ($Output) { $pyArgs += "--output"; $pyArgs += $Output }
    }
    "extract" {
        if (-not $Input) { Write-Error "Input file required for extract action"; exit 1 }
        $pyArgs += $Input
        if ($Output) { $pyArgs += "--output"; $pyArgs += $Output }
    }
    "add-paragraph" {
        if (-not $Input) { $Input = "output.docx" }
        $pyArgs += "--input"; $pyArgs += $Input
        if ($Text) { $pyArgs += "--text"; $pyArgs += $Text }
        $pyArgs += "--style"; $pyArgs += $Style
        if ($Bold) { $pyArgs += "--bold" }
        if ($Italic) { $pyArgs += "--italic" }
        $pyArgs += "--align"; $pyArgs += $Align
        if ($Output) { $pyArgs += "--output"; $pyArgs += $Output }
    }
    "add-heading" {
        if (-not $Input) { $Input = "output.docx" }
        $pyArgs += "--input"; $pyArgs += $Input
        if ($Text) { $pyArgs += "--text"; $pyArgs += $Text }
        $pyArgs += "--level"; $pyArgs += $Level.ToString()
        if ($Output) { $pyArgs += "--output"; $pyArgs += $Output }
    }
    "add-table" {
        if (-not $Input) { $Input = "output.docx" }
        $pyArgs += "--input"; $pyArgs += $Input
        if ($Headers) { $pyArgs += "--headers"; $pyArgs += $Headers }
        if ($Data) { $pyArgs += "--data"; $pyArgs += $Data }
        if ($Output) { $pyArgs += "--output"; $pyArgs += $Output }
    }
    "set-style" {
        if (-not $Input) { Write-Error "Input file required for set-style action"; exit 1 }
        $pyArgs += "--input"; $pyArgs += $Input
        $pyArgs += "--style"; $pyArgs += $Style
        if ($Output) { $pyArgs += "--output"; $pyArgs += $Output }
    }
}

Write-Host "Executing: python $PythonScript $($pyArgs -join ' ')" -ForegroundColor Cyan

try {
    $result = & python $PythonScript @pyArgs 2>&1
    Write-Host $result
    exit 0
}
catch {
    Write-Error "Error executing Python script: $_"
    exit 1
}
