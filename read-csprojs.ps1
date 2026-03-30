[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$files = Get-ChildItem 'D:\OpenClaw\.openclaw\workspace\CadAttrBlockConverter\src-multi\*.csproj' -File
foreach ($f in $files) {
    Write-Host "===FILE==="
    Write-Host $f.Name
    Write-Host "===CONTENT==="
    $content = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    Write-Host $content.Substring(0, [Math]::Min(600, $content.Length))
    Write-Host "==="
}
