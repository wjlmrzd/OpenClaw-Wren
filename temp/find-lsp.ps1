[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$out = @()

# Search for .lsp files in various locations
$searchPaths = @("D:\OpenClaw", "D:\OpenClawWorkspace", "C:\Users\Administrator\Desktop", "C:\Users\Administrator\Documents", "E:\cad2022")

foreach ($path in $searchPaths) {
    if (Test-Path $path) {
        $out += "=== $path .lsp files ==="
        Get-ChildItem $path -File -Recurse -Filter "*.lsp" -Depth 5 -ErrorAction SilentlyContinue | Select-Object -First 20 | ForEach-Object {
            $out += $_.FullName
        }
    }
}

$out | Out-File -FilePath "D:\OpenClaw\.openclaw\workspace\temp\find-lsp.txt" -Encoding UTF8
Write-Output "Done"
