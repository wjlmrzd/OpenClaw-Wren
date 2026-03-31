param(
    [string]$Action = "list",
    [string]$Query = "",
    [int]$Page = 1,
    [int]$PageSize = 8
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"

$EdgePath = "$env:USERPROFILE\AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks"
$ChromePath = "$env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"
$CacheFile = "$env:TEMP\openclaw_bookmarks_cache.json"

function Get-BookmarkItems {
    param($folder, $source, $path = "")
    $items = @()
    if ($folder.PSObject.Properties.Name -contains "children") {
        foreach ($child in $folder.children) {
            if ($child.type -eq "folder") {
                $newPath = if ($path) { "$path > $($child.name)" } else { $child.name }
                $items += Get-BookmarkItems -folder $child -source $source -path $newPath
            } elseif ($child.type -eq "url") {
                $items += [PSCustomObject]@{
                    Id = [guid]::NewGuid().ToString("N")
                    Source = $source
                    Path = $path
                    Name = $child.name
                    Url = $child.url
                    Visits = if ($child.PSObject.Properties.Name -contains "visit_count") { $child.visit_count } else { 0 }
                }
            }
        }
    }
    return $items
}

function Parse-Bookmarks {
    param($file, $source)
    if (Test-Path $file) {
        try {
            $content = Get-Content $file -Raw -Encoding UTF8
            $data = $content | ConvertFrom-Json
            $items = @()
            $data.roots.PSObject.Properties | ForEach-Object {
                $items += Get-BookmarkItems -folder $_.Value -source $source -path $_.Name
            }
            return $items
        } catch { return @() }
    }
    return @()
}

function Get-Bookmarks {
    if (Test-Path $CacheFile) {
        $cacheAge = (Get-Date) - (Get-Item $CacheFile).LastWriteTime
        if ($cacheAge.TotalMinutes -lt 5) {
            return (Get-Content $CacheFile -Raw | ConvertFrom-Json)
        }
    }
    
    $all = @()
    $all += Parse-Bookmarks -file $EdgePath -source "Edge"
    $all += Parse-Bookmarks -file $ChromePath -source "Chrome"
    $all = $all | Where-Object { $_.Url -and $_.Url.Trim() -ne "" -and $_.Url -match "^https?://" }
    $all = $all | Sort-Object { -$_.Visits }
    
    $all | ConvertTo-Json -Depth 5 | Set-Content $CacheFile -Encoding UTF8
    return $all
}

$allBookmarks = Get-Bookmarks
$total = $allBookmarks.Count
$edgeCount = ($allBookmarks | Where-Object { $_.Source -eq "Edge" }).Count
$chromeCount = ($allBookmarks | Where-Object { $_.Source -eq "Chrome" }).Count

if ($Action -eq "list") {
    if ($Query) {
        $q = $Query.ToLower()
        $filtered = $allBookmarks | Where-Object { 
            $_.Name.ToLower().Contains($q) -or $_.Url.ToLower().Contains($q) -or $_.Path.ToLower().Contains($q) 
        }
    } else {
        $filtered = $allBookmarks
    }
    
    $totalFiltered = $filtered.Count
    $totalPages = [Math]::Ceiling($totalFiltered / $PageSize)
    if ($Page -gt $totalPages) { $Page = $totalPages }
    if ($Page -lt 1) { $Page = 1 }
    
    $start = ($Page - 1) * $PageSize
    $pageItems = $filtered | Select-Object -Skip $start -First $PageSize
    
    $keyboard = @()
    
    foreach ($bm in $pageItems) {
        $shortName = if ($bm.Name.Length -gt 30) { $bm.Name.Substring(0, 27) + "..." } else { $bm.Name }
        $src = if ($bm.Source -eq "Edge") { "[E]" } else { "[C]" }
        
        $btn = @{
            text = "$src $shortName"
            callback_data = "bm_search:$($bm.Id)"
        }
        $keyboard += ,@($btn)
    }
    
    # Navigation
    $navRow = @()
    if ($Page -gt 1) {
        $navRow += @{ text = "< Prev"; callback_data = "bm_page:$($Page - 1):$($Query)" }
    }
    $navRow += @{ text = "$Page / $totalPages"; callback_data = "bm_noop" }
    if ($Page -lt $totalPages) {
        $navRow += @{ text = "Next >"; callback_data = "bm_page:$($Page + 1):$($Query)" }
    }
    $keyboard += ,@($navRow)
    
    # Action row
    $keyboard += ,@(
        @{ text = "[Search]"; callback_data = "bm_action:search" },
        @{ text = "[Refresh]"; callback_data = "bm_action:refresh" }
    )
    
    @{
        action = "list"
        text = "Bookmark Search`nEdge: $edgeCount | Chrome: $chromeCount | Total: $total`nFilter: ""$Query"" => $totalFiltered results"
        keyboard = $keyboard
        totalFiltered = $totalFiltered
        page = $Page
        totalPages = $totalPages
    } | ConvertTo-Json -Depth 10
}
elseif ($Action -eq "get") {
    $bm = $allBookmarks | Where-Object { $_.Id -eq $Query } | Select-Object -First 1
    if ($bm) {
        @{
            action = "get"
            id = $bm.Id
            name = $bm.Name
            url = $bm.Url
            source = $bm.Source
            path = $bm.Path
        } | ConvertTo-Json -Depth 3
    } else {
        @{ action = "get"; error = "Not found" } | ConvertTo-Json
    }
}
