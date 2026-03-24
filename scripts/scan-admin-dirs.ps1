# 扫描用户目录下的大文件夹
$folders = Get-ChildItem -Path "C:\Users\Administrator" -Directory -ErrorAction SilentlyContinue
$results = @()
foreach ($folder in $folders) {
    try {
        $size = (Get-ChildItem -Path $folder.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        if ($size -gt 50MB) {
            $results += [PSCustomObject]@{
                Folder = $folder.Name
                SizeGB = [math]::Round($size / 1GB, 3)
                SizeMB = [math]::Round($size / 1MB, 1)
            }
        }
    } catch {}
}
$results | Sort-Object SizeGB -Descending | Format-Table -AutoSize
