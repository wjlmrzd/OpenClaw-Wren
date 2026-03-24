# 扫描 C 盘大文件夹
$folders = Get-ChildItem -Path "C:\" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch "^\$|Recovery|System Volume|Windows|Program Files|Program Files \(x86\)|PerfLogs" }
$results = @()
foreach ($folder in $folders) {
    try {
        $size = (Get-ChildItem -Path $folder.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        if ($size -gt 100MB) {
            $results += [PSCustomObject]@{
                Folder = $folder.Name
                SizeGB = [math]::Round($size / 1GB, 2)
            }
        }
    } catch {}
}
$results | Sort-Object SizeGB -Descending | Format-Table -AutoSize
