$searchCode = "0881c24562d14415aee72584c05c99d3"
$bookmarkPath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Bookmarks"

Write-Host "=== Bookmark Search: $searchCode ==="
Write-Host "Path: $bookmarkPath"

if (Test-Path $bookmarkPath) {
    $content = Get-Content -Path $bookmarkPath -Raw -Encoding UTF8
    $json = $content | ConvertFrom-Json
    
    function Search-Bookmarks {
        param($items)
        foreach ($item in $items) {
            if ($item.PSObject.Properties.Name -contains 'url') {
                if ($item.url -match $searchCode -or $item.name -match $searchCode) {
                    Write-Host "Found: $($item.name)"
                    Write-Host "URL: $($item.url)"
                    Write-Host "---"
                }
            } else {
                if ($item.name -match $searchCode) {
                    Write-Host "Found Folder: $($item.name)"
                    Write-Host "---"
                }
            }
            if ($item.PSObject.Properties.Name -contains 'children' -and $item.children) {
                Search-Bookmarks -items $item.children
            }
        }
    }
    
    $bar = $json.roots.bookmark_bar.children
    $other = $json.roots.other.children
    
    Search-Bookmarks -items $bar
    Search-Bookmarks -items $other
    Write-Host "Search complete."
} else {
    Write-Host "Bookmark file not found!"
}
