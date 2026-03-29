# Final vault structure check
$vault = 'E:\software\Obsidian\vault'
Write-Host '=== Vault root ==='
Get-ChildItem (Join-Path $vault '') -Filter '*.md' | ForEach-Object { Write-Host ('  ' + $_.Name) }

Write-Host ''
Write-Host '=== 02_Areas ==='
Get-ChildItem (Join-Path $vault '02_Areas') -Filter '*.md' | Measure-Object | ForEach-Object { Write-Host ('  Root files: ' + $_.Count) }
Get-ChildItem (Join-Path $vault '02_Areas') -Directory | ForEach-Object {
    $cnt = (Get-ChildItem $_.FullName -Filter '*.md' | Measure-Object).Count
    Write-Host ('  Subdir [' + $_.Name + ']: ' + $cnt + ' files')
}

Write-Host ''
Write-Host '=== 03_Resources ==='
Get-ChildItem (Join-Path $vault '03_Resources') -Filter '*.md' | Measure-Object | ForEach-Object { Write-Host ('  Root files: ' + $_.Count) }
Get-ChildItem (Join-Path $vault '03_Resources') -Directory | ForEach-Object {
    $cnt = (Get-ChildItem $_.FullName -Filter '*.md' | Measure-Object).Count
    Write-Host ('  Subdir [' + $_.Name + ']: ' + $cnt + ' files')
}
