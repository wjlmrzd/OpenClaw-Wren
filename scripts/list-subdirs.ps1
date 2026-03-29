$vault = 'E:\software\Obsidian\vault'
Get-ChildItem (Join-Path $vault '02_Areas') -Directory | ForEach-Object {
    $subDir = $_.FullName
    Write-Host ('[' + $_.Name + ']')
    Get-ChildItem $subDir -Filter '*.md' | ForEach-Object {
        Write-Host ('  ' + $_.Name)
    }
}
Write-Host ''
Write-Host '[02_Areas root files]'
Get-ChildItem (Join-Path $vault '02_Areas') -Filter '*.md' | ForEach-Object {
    Write-Host ('  ' + $_.Name)
}
Write-Host ''
Write-Host '[03_Resources root files]'
Get-ChildItem (Join-Path $vault '03_Resources') -Filter '*.md' | ForEach-Object {
    Write-Host ('  ' + $_.Name)
}
Write-Host '[03_Resources subdirs]'
Get-ChildItem (Join-Path $vault '03_Resources') -Directory | ForEach-Object {
    Write-Host ('  [' + $_.Name + ']')
    Get-ChildItem $_.FullName -Filter '*.md' | ForEach-Object {
        Write-Host ('    ' + $_.Name)
    }
}
