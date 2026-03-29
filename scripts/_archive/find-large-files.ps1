Get-ChildItem -Path C:\ -Recurse -File -ErrorAction SilentlyContinue | 
Where-Object { $PSItem.Length -gt 100MB } | 
Sort-Object Length -Descending | 
Select-Object -First 20 FullName, @{Name='SizeMB';Expression={[int]($PSItem.Length/1MB)}}
