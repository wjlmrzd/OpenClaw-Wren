# -*- coding: utf-8 -*-
<#
.SYNOPSIS
    Excel Data Processor - PowerShell wrapper for excel_processor.py
    
.DESCRIPTION
    Read, write, format Excel files and create charts using openpyxl
    
.PARAMETER Action
    Action: read, write, format, chart
    
.PARAMETER Input
    Input Excel file path
    
.PARAMETER Output
    Output file path
    
.PARAMETER Sheet
    Sheet name or index (default: 0)
    
.PARAMETER Cell
    Single cell reference (e.g., "A1")
    
.PARAMETER Range
    Cell range (e.g., "A1:C10")
    
.PARAMETER Data
    Data to write (key=value pairs or array)
    
.PARAMETER Headers
    Column headers for new files
    
.PARAMETER ChartType
    Chart type: Bar, Line, Pie
    
.PARAMETER ChartTitle
    Chart title
    
.EXAMPLE
    .\excel-data-processor.ps1 -Action read -Input "data.xlsx" -Sheet "Sheet1"
    .\excel-data-processor.ps1 -Action write -Output "output.xlsx" -Headers "Name" "Value" -Data "Item1,100" "Item2,200"
    .\excel-data-processor.ps1 -Action chart -Input "data.xlsx" -Output "chart.xlsx" -ChartType "Bar"
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("read", "write", "format", "chart")]
    [string]$Action,
    
    [Parameter()]
    [string]$Input,
    
    [Parameter()]
    [string]$Output,
    
    [Parameter()]
    [string]$Sheet = "0",
    
    [Parameter()]
    [string]$Cell,
    
    [Parameter()]
    [string]$Range,
    
    [Parameter()]
    [string]$Data,
    
    [Parameter()]
    [string[]]$Headers,
    
    [Parameter()]
    [string]$CellRef,
    
    [Parameter()]
    [switch]$Bold,
    
    [Parameter()]
    [switch]$Italic,
    
    [Parameter()]
    [int]$FontSize = 12,
    
    [Parameter()]
    [string]$FontColor,
    
    [Parameter()]
    [string]$BgColor,
    
    [Parameter()]
    [string]$Align = "left",
    
    [Parameter()]
    [string]$ChartType = "Bar",
    
    [Parameter()]
    [string]$ChartTitle = "Chart",
    
    [Parameter()]
    [string]$ChartRange,
    
    [Parameter()]
    [string]$ChartPosition = "E2",
    
    [Parameter()]
    [string]$SheetName = "Sheet1"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PythonScript = Join-Path $ScriptDir "excel_processor.py"

if (-not (Test-Path $PythonScript)) {
    Write-Error "Python script not found: $PythonScript"
    exit 1
}

# Build arguments
$pyArgs = @($Action)

switch ($Action) {
    "read" {
        if ($Input) { $pyArgs += "--input"; $pyArgs += $Input }
        $pyArgs += "--sheet"; $pyArgs += $Sheet
        if ($Cell) { $pyArgs += "--cell"; $pyArgs += $Cell }
        if ($Range) { $pyArgs += "--range"; $pyArgs += $Range }
    }
    "write" {
        if (-not $Output) { Write-Error "Output file required for write action"; exit 1 }
        $pyArgs += "--output"; $pyArgs += $Output
        if ($Headers) { $pyArgs += "--headers"; $pyArgs += $Headers }
        if ($Data) { 
            $dataArray = $Data -split ' '
            $pyArgs += "--data"
            foreach ($item in $dataArray) { $pyArgs += $item }
        }
        $pyArgs += "--sheet-name"; $pyArgs += $SheetName
    }
    "format" {
        if (-not $Input) { Write-Error "Input file required for format action"; exit 1 }
        if (-not $Output) { $Output = $Input }
        $pyArgs += "--input"; $pyArgs += $Input
        $pyArgs += "--output"; $pyArgs += $Output
        if ($CellRef) { $pyArgs += "--cell-ref"; $pyArgs += $CellRef }
        if ($Bold) { $pyArgs += "--bold" }
        if ($Italic) { $pyArgs += "--italic" }
        $pyArgs += "--font-size"; $pyArgs += $FontSize.ToString()
        if ($FontColor) { $pyArgs += "--font-color"; $pyArgs += $FontColor }
        if ($BgColor) { $pyArgs += "--bg-color"; $pyArgs += $BgColor }
        $pyArgs += "--align"; $pyArgs += $Align
    }
    "chart" {
        if (-not $Input) { Write-Error "Input file required for chart action"; exit 1 }
        if (-not $Output) { $Output = $Input }
        $pyArgs += "--input"; $pyArgs += $Input
        $pyArgs += "--output"; $pyArgs += $Output
        $pyArgs += "--chart-type"; $pyArgs += $ChartType
        $pyArgs += "--chart-title"; $pyArgs += $ChartTitle
        if ($ChartRange) { $pyArgs += "--chart-range"; $pyArgs += $ChartRange }
        $pyArgs += "--chart-position"; $pyArgs += $ChartPosition
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
