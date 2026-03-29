$vols = Get-Volume | Where-Object { $_.DriveLetter }
foreach ($v in $vols) {
    $used = ($v.Size - $v.SizeRemaining) / $v.Size * 100
    $freeGB = [math]::Round($v.SizeRemaining / 1GB, 1)
    $totalGB = [math]::Round($v.Size / 1GB, 1)
    $usedPercent = [math]::Round($used, 1)
    Write-Output "$($v.DriveLetter): Free=$freeGB GB / Total=$totalGB GB (Used: $usedPercent%)"
}
