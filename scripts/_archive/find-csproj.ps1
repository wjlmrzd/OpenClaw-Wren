Get-ChildItem 'D:\OpenClaw\.openclaw\workspace\CadAttrBlockConverter' -Directory | ForEach-Object {
    $csproj = Get-ChildItem ($_.FullName + '\*.csproj') -EA SilentlyContinue | Select-Object -First 1
    if ($csproj) {
        Write-Host "DIR: $($_.Name) | PROJ: $($csproj.Name)"
    }
}
