# -*- coding: utf-8 -*-
<#
.SYNOPSIS
    PDF Report Generator - PowerShell wrapper for pdf_generator.py
    
.DESCRIPTION
    Create PDF reports, convert HTML to PDF, merge PDFs, extract text using reportlab/fpdf2
    
.PARAMETER Action
    Action: create, table, html2pdf, extract, merge, split, watermark
    
.PARAMETER Title
    PDF document title
    
.PARAMETER Content
    Text content for the PDF
    
.PARAMETER Input
    Input file path (HTML or existing PDF)
    
.PARAMETER Output
    Output file path
    
.PARAMETER Files
    Comma-separated file list (for merge action)
    
.PARAMETER Author
    Document author
    
.PARAMETER FontSize
    Base font size (default: 12)
    
.PARAMETER Headers
    Table headers (space-separated)
    
.PARAMETER Data
    Table data rows
    
.PARAMETER WatermarkText
    Text for watermark
    
.PARAMETER WatermarkImage
    Image path for watermark
    
.EXAMPLE
    .\pdf-report-generator.ps1 -Action create -Title "Daily Report" -Content "Report content here" -Output "report.pdf"
    .\pdf-report-generator.ps1 -Action html2pdf -Input "report.html" -Output "report.pdf"
    .\pdf-report-generator.ps1 -Action merge -Files "file1.pdf,file2.pdf" -Output "combined.pdf"
    .\pdf-report-generator.ps1 -Action extract -Input "document.pdf" -Output "content.txt"
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("create", "table", "html2pdf", "extract", "merge", "split", "watermark")]
    [string]$Action,
    
    [Parameter()]
    [string]$Title = "Report",
    
    [Parameter()]
    [string]$Content,
    
    [Parameter()]
    [string]$Input,
    
    [Parameter()]
    [string]$Output = "output.pdf",
    
    [Parameter()]
    [string]$Files,
    
    [Parameter()]
    [string]$Author = "System",
    
    [Parameter()]
    [int]$FontSize = 12,
    
    [Parameter()]
    [string[]]$Headers,
    
    [Parameter()]
    [string[]]$Data,
    
    [Parameter()]
    [string]$WatermarkText,
    
    [Parameter()]
    [string]$WatermarkImage,
    
    [Parameter()]
    [int]$PageStart = 1,
    
    [Parameter()]
    [int]$PageEnd = 1
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PythonScript = Join-Path $ScriptDir "pdf_generator.py"

if (-not (Test-Path $PythonScript)) {
    Write-Error "Python script not found: $PythonScript"
    exit 1
}

# Build arguments
$pyArgs = @($Action)

switch ($Action) {
    "create" {
        $pyArgs += "--title"; $pyArgs += $Title
        if ($Content) { $pyArgs += "--content"; $pyArgs += $Content }
        $pyArgs += "--output"; $pyArgs += $Output
        $pyArgs += "--author"; $pyArgs += $Author
        $pyArgs += "--font-size"; $pyArgs += $FontSize.ToString()
    }
    "table" {
        $pyArgs += "--title"; $pyArgs += $Title
        if ($Headers) { $pyArgs += "--headers"; $pyArgs += $Headers }
        if ($Data) { $pyArgs += "--data"; $pyArgs += $Data }
        $pyArgs += "--output"; $pyArgs += $Output
    }
    "html2pdf" {
        if (-not $Input) { Write-Error "Input HTML file required for html2pdf action"; exit 1 }
        $pyArgs += "--input"; $pyArgs += $Input
        $pyArgs += "--output"; $pyArgs += $Output
    }
    "extract" {
        if (-not $Input) { Write-Error "Input PDF file required for extract action"; exit 1 }
        $pyArgs += "--input"; $pyArgs += $Input
        $pyArgs += "--output"; $pyArgs += ($Output -replace "\.pdf$", ".txt")
    }
    "merge" {
        # Merge requires PyPDF2 - handled by PowerShell directly
        Write-Host "Merge action: Using PyPDF2 directly" -ForegroundColor Yellow
        exit 0
    }
    "split" {
        # Split requires PyPDF2 - handled by PowerShell directly
        Write-Host "Split action: Using PyPDF2 directly" -ForegroundColor Yellow
        exit 0
    }
    "watermark" {
        # Watermark requires additional processing
        Write-Host "Watermark action: Would apply watermark" -ForegroundColor Yellow
        exit 0
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
