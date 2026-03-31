$searchTerm = "0881c245"
$edgeDataPath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"

Write-Host "Searching Edge data for: $searchTerm`n"

$results = Get-ChildItem $edgeDataPath -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -in '.json','.db','.txt','.html' } |
    ForEach-Object {
        try {
            $content = Get-Content $_.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if ($content -match $searchTerm) {
                [PSCustomObject]@{
                    File = $_.FullName
                    Match = ($content -split "`n" | Where-Object { $_ -match $searchTerm } | Select-Object -First 2) -join " | "
                }
            }
        } catch {}
    }

if ($results) {
    $results | ForEach-Object {
        Write-Host "File: $($_.File)"
        Write-Host "Match: $($_.Match)"
        Write-Host "---"
    }
} else {
    Write-Host "No results found in Edge data"
}

# Also check browser history
Write-Host "`nChecking History..."
$historyPath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\History"
if (Test-Path $historyPath) {
    Write-Host "History file exists at: $historyPath"
    Write-Host "(SQLite DB - requires separate query tool)"
}
