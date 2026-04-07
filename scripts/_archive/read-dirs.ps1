Get-ChildItem 'D:\OpenClaw\.openclaw\workspace\CadAttrBlockConverter' -Directory | ForEach-Object {
    $name = $_.Name
    $csprojFiles = Get-ChildItem ($_.FullName + '\*.csproj') -File -EA SilentlyContinue
    $csprojName = if ($csprojFiles) { $csprojFiles[0].Name } else { '(none)' }
    Write-Host "NAME:$name|CSPROJ:$csprojName"
}
