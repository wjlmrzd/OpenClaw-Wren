$b = Get-Content 'C:\Users\Administrator\AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks' -Raw | ConvertFrom-Json

function Get-URLs($node) {
    if ($node.type -eq 'url') { $node.url }
    if ($node.children) { $node.children | ForEach-Object { Get-URLs $_ } }
}

$allUrls = Get-URLs $b.roots
$filtered = $allUrls | Where-Object { 
    $_ -notmatch 'login|signin|account|#|javascript' -and 
    $_.StartsWith('http')
} | Select-Object -Unique

$filtered | ForEach-Object { $_ }
