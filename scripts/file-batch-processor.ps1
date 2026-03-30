# -*- coding: utf-8 -*-
<#
.SYNOPSIS
    File Batch Processor - Batch rename, convert, and organize files
    
.DESCRIPTION
    Perform batch operations on files:
    - rename: Batch rename files with pattern matching
    - convert: Convert files between formats
    - organize: Organize files by date, type, or size
    - copy: Copy files to destination
    - delete: Delete files matching pattern
    
.PARAMETER Action
    Action to perform: rename, convert, organize, copy, delete
    
.PARAMETER Pattern
    File pattern to match (e.g., "*.xlsx", "*.*")
    
.PARAMETER From
    Text to find (for rename action)
    
.PARAMETER To
    Text to replace (for rename action)
    
.PARAMETER Input
    Input file or folder
    
.PARAMETER Source
    Source folder (for organize/copy actions)
    
.PARAMETER Dest
    Destination folder
    
.PARAMETER By
    Organization method: date, type, size, name
    
.PARAMETER FromFormat
    Source format (for convert action)
    
.PARAMETER ToFormat
    Target format (for convert action)
    
.PARAMETER Recursive
    Process subdirectories recursively
    
.PARAMETER Preview
    Show what would be done without making changes
    
.EXAMPLE
    .\file-batch-processor.ps1 -Action rename -Pattern "*.dwg" -From "老_" -To "新_" -Source "C:\Files"
    .\file-batch-processor.ps1 -Action convert -Input "*.xlsx" -From "xlsx" -To "csv" -Source "C:\Data"
    .\file-batch-processor.ps1 -Action organize -Source "C:\Downloads" -By "date" -Dest "D:\Archive" -Preview
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("rename", "convert", "organize", "copy", "delete")]
    [string]$Action,
    
    [Parameter()]
    [string]$Pattern = "*.*",
    
    [Parameter()]
    [string]$From,
    
    [Parameter()]
    [string]$To,
    
    [Parameter()]
    [string]$Input,
    
    [Parameter()]
    [string]$Source,
    
    [Parameter()]
    [string]$Dest,
    
    [Parameter()]
    [ValidateSet("date", "type", "size", "name")]
    [string]$By = "type",
    
    [Parameter()]
    [string]$FromFormat,
    
    [Parameter()]
    [string]$ToFormat,
    
    [Parameter()]
    [switch]$Recursive,
    
    [Parameter()]
    [switch]$Preview,
    
    [Parameter()]
    [int]$MaxFiles = 1000
)

$ErrorActionPreference = "Stop"

function Write-Operation {
    param([string]$Msg, [string]$Color = "White")
    if ($Preview) {
        Write-Host "[PREVIEW] $Msg" -ForegroundColor Yellow
    } else {
        Write-Host $Msg -ForegroundColor $Color
    }
}

function Get-Files {
    param([string]$Path, [string]$Pattern)
    
    if (Test-Path $Path) {
        if ((Get-Item $Path).PSIsContainer) {
            $gciArgs = @{
                Path = $Path
                Filter = $Pattern
                Recurse = $Recursive
                ErrorAction = "SilentlyContinue"
            }
            Get-ChildItem @gciArgs | Where-Object { -not $_.PSIsContainer }
        } else {
            Get-Item $Path
        }
    }
}

# Resolve paths
$SourcePath = if ($Source) { $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Source) } else { $PWD.Path }
$DestPath = if ($Dest) { $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Dest) } else { $PWD.Path }

Write-Host "=== File Batch Processor ===" -ForegroundColor Green
Write-Host "Action: $Action" -ForegroundColor Cyan
Write-Host "Source: $SourcePath" -ForegroundColor Cyan
if ($Dest) { Write-Host "Dest: $DestPath" -ForegroundColor Cyan }
if ($Preview) { Write-Host "[PREVIEW MODE - No changes will be made]" -ForegroundColor Yellow }
Write-Host ""

$processed = 0
$errors = 0

switch ($Action) {
    "rename" {
        if (-not $From) { Write-Error "From parameter required for rename action"; exit 1 }
        
        $files = Get-Files $SourcePath $Pattern
        Write-Host "Found $($files.Count) files matching '$Pattern'" -ForegroundColor Gray
        
        foreach ($file in $files) {
            if ($processed -ge $MaxFiles) { 
                Write-Host "Max files limit reached ($MaxFiles)" -ForegroundColor Yellow
                break 
            }
            
            $newName = $file.Name -replace [regex]::Escape($From), $To
            
            if ($newName -ne $file.Name) {
                $newPath = Join-Path $file.DirectoryName $newName
                Write-Operation "Rename: '$($file.Name)' -> '$newName'"
                
                if (-not $Preview) {
                    try {
                        Rename-Item -Path $file.FullName -NewName $newName -ErrorAction Stop
                    } catch {
                        Write-Warning "Failed to rename '$($file.Name)': $_"
                        $errors++
                    }
                }
                $processed++
            }
        }
    }
    
    "convert" {
        if (-not $FromFormat -or -not $ToFormat) { 
            Write-Error "FromFormat and ToFormat required for convert action" 
            exit 1 
        }
        
        $pattern = "*.$FromFormat"
        $files = Get-Files $SourcePath $pattern
        Write-Host "Found $($files.Count) files to convert" -ForegroundColor Gray
        
        foreach ($file in $files) {
            if ($processed -ge $MaxFiles) { break }
            
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
            $newName = "$baseName.$ToFormat"
            $newPath = Join-Path $file.DirectoryName $newName
            
            Write-Operation "Convert: '$($file.Name)' -> '$newName'"
            
            if (-not $Preview) {
                try {
                    # For Excel to CSV
                    if ($FromFormat -eq "xlsx" -and $ToFormat -eq "csv") {
                        $excel = New-Object -ComObject Excel.Application
                        $excel.Visible = $false
                        $excel.DisplayAlerts = $false
                        
                        $workbook = $excel.Workbooks.Open($file.FullName)
                        $workbook.SaveAs($newPath, 6)  # 6 = CSV
                        $workbook.Close()
                        $excel.Quit()
                        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
                    }
                    # For DOCX to PDF
                    elseif ($FromFormat -eq "docx" -and $ToFormat -eq "pdf") {
                        $word = New-Object -ComObject Word.Application
                        $word.Visible = $false
                        
                        $doc = $word.Documents.Open($file.FullName)
                        $doc.SaveAs($newPath, 17)  # 17 = PDF
                        $doc.Close()
                        $word.Quit()
                        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
                    }
                    else {
                        Copy-Item $file.FullName $newPath
                    }
                } catch {
                    Write-Warning "Failed to convert '$($file.Name)': $_"
                    $errors++
                }
            }
            $processed++
        }
    }
    
    "organize" {
        if (-not (Test-Path $DestPath)) {
            if ($Preview) {
                Write-Operation "Would create destination: $DestPath"
            } else {
                New-Item -ItemType Directory -Path $DestPath -Force | Out-Null
            }
        }
        
        $files = Get-Files $SourcePath $Pattern
        Write-Host "Organizing $($files.Count) files by '$By'" -ForegroundColor Gray
        
        foreach ($file in $files) {
            if ($processed -ge $MaxFiles) { break }
            
            switch ($By) {
                "date" {
                    $date = $file.LastWriteTime.ToString("yyyy-MM-dd")
                    $subFolder = Join-Path $DestPath $date
                }
                "type" {
                    $ext = $file.Extension.TrimStart(".").ToUpper()
                    if (-not $ext) { $ext = "NoExtension" }
                    $subFolder = Join-Path $DestPath $ext
                }
                "size" {
                    $sizeKB = $file.Length / 1KB
                    if ($sizeKB -lt 100) { $subFolder = Join-Path $DestPath "Small" }
                    elseif ($sizeKB -lt 10000) { $subFolder = Join-Path $DestPath "Medium" }
                    else { $subFolder = Join-Path $DestPath "Large" }
                }
                "name" {
                    $firstChar = $file.Name[0].ToString().ToUpper()
                    if ($firstChar -match '[^a-zA-Z0-9]') { $firstChar = "#" }
                    $subFolder = Join-Path $DestPath $firstChar
                }
            }
            
            if (-not (Test-Path $subFolder)) {
                if (-not $Preview) {
                    New-Item -ItemType Directory -Path $subFolder -Force | Out-Null
                } else {
                    Write-Operation "Would create folder: $subFolder"
                }
            }
            
            $destFile = Join-Path $subFolder $file.Name
            
            # Handle duplicate names
            $counter = 1
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
            $extension = [System.IO.Path]::GetExtension($file.Name)
            while (Test-Path $destFile) {
                $destFile = Join-Path $subFolder "$baseName`_$counter$extension"
                $counter++
            }
            
            Write-Operation "Move: '$($file.Name)' -> '$destFile'"
            
            if (-not $Preview) {
                try {
                    Move-Item $file.FullName $destFile -ErrorAction Stop
                } catch {
                    Write-Warning "Failed to move '$($file.Name)': $_"
                    $errors++
                }
            }
            $processed++
        }
    }
    
    "copy" {
        if (-not $Dest) { Write-Error "Dest parameter required for copy action"; exit 1 }
        if (-not (Test-Path $DestPath)) {
            if (-not $Preview) { New-Item -ItemType Directory -Path $DestPath -Force | Out-Null }
        }
        
        $files = Get-Files $SourcePath $Pattern
        Write-Host "Copying $($files.Count) files" -ForegroundColor Gray
        
        foreach ($file in $files) {
            if ($processed -ge $MaxFiles) { break }
            
            $destFile = Join-Path $DestPath $file.Name
            Write-Operation "Copy: '$($file.FullName)' -> '$destFile'"
            
            if (-not $Preview) {
                try {
                    Copy-Item $file.FullName $destFile -ErrorAction Stop
                } catch {
                    Write-Warning "Failed to copy '$($file.Name)': $_"
                    $errors++
                }
            }
            $processed++
        }
    }
    
    "delete" {
        Write-Host "WARNING: Delete action will remove files!" -ForegroundColor Red
        $confirmation = Read-Host "Type 'yes' to confirm"
        if ($confirmation -ne "yes") {
            Write-Host "Cancelled." -ForegroundColor Yellow
            exit 0
        }
        
        $files = Get-Files $SourcePath $Pattern
        Write-Host "Found $($files.Count) files to delete" -ForegroundColor Gray
        
        foreach ($file in $files) {
            if ($processed -ge $MaxFiles) { break }
            
            Write-Operation "DELETE: '$($file.FullName)'"
            
            if (-not $Preview) {
                try {
                    Remove-Item $file.FullName -Force -ErrorAction Stop
                } catch {
                    Write-Warning "Failed to delete '$($file.Name)': $_"
                    $errors++
                }
            }
            $processed++
        }
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Green
Write-Host "Processed: $processed files"
if ($errors -gt 0) {
    Write-Host "Errors: $errors" -ForegroundColor Red
}
