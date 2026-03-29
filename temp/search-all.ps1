[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$out = @()

# Search D:\ for any item containing key terms (excluding very large dirs)
$excludeDirs = @("OpenClaw", "下载", "BaiduNetdiskDownload", "QLDownload", "System Volume Information", "$RECYCLE.BIN", "Catalog.wci")

$out += "=== Searching D:\ for projects/folders ==="

# List all top-level directories on D:
Get-ChildItem "D:\" -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
    $name = $_.Name
    $shouldExclude = $false
    foreach ($ex in $excludeDirs) {
        if ($name -eq $ex) {
            $shouldExclude = $true
            break
        }
    }
    if (-not $shouldExclude) {
        $out += "[DIR] $name"
    }
}

# Also check if there's a folder matching "my*" pattern
$out += ""
$out += "=== Checking for 'my' pattern ==="
Get-ChildItem "D:\" -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*my*" -or $_.Name -like "*My*" } | ForEach-Object {
    $out += $_.FullName
}

$out | Out-File -FilePath "D:\OpenClaw\.openclaw\workspace\temp\search-all.txt" -Encoding UTF8
Write-Output "Done"
