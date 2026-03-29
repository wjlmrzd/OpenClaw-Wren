$files = @(
    'D:\OpenClaw\.openclaw\workspace\openclaw.json',
    'D:\OpenClaw\.openclaw\workspace\cron\jobs.json'
)
$files | ForEach-Object {
    $file = $_
    if (Test-Path $file) {
        $hash = (Get-FileHash $file -Algorithm SHA256).Hash
        $mtime = (Get-Item $file).LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
        $name = Split-Path $file -Leaf
        Write-Host "$name|$($hash.Substring(0,16))|$mtime"
    }
}
