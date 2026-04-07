Get-PSDrive C,D | ForEach-Object {
    $total = $_.Used + $_.Free
    $pct = [math]::Round($_.Used / $total * 100, 1)
    Write-Output "$($_.Name): Used=$([math]::Round($_.Used/1GB,1))GB Free=$([math]::Round($_.Free/1GB,1))GB Pct=$pct%"
}
