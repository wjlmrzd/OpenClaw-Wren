$path = "C:\Users\Administrator\AppData\Roaming\npm\node_modules\openclaw-cn\dist\telegram\bot\delivery.js"
$content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

$old = @'
    const fetched = await fetchRemoteMedia({
        url,
        fetchImpl,
        filePathHint: file.file_path,
    });
    const originalName = fetched.fileName ?? file.file_path;
    const saved = await saveMediaBuffer(fetched.buffer, fetched.contentType, "inbound", maxBytes, originalName);
    let placeholder = "<media:document>";
'@

$new = @'
    const fetched = await fetchRemoteMedia({
        url,
        fetchImpl,
        filePathHint: file.file_path,
        ssrfPolicy: { allowedHostnames: ["api.telegram.org"] },
    });
    const originalName = fetched.fileName ?? file.file_path;
    const saved = await saveMediaBuffer(fetched.buffer, fetched.contentType, "inbound", maxBytes, originalName);
    let placeholder = "<media:document>";
'@

if ($content.Contains($old)) {
    $content = $content.Replace($old, $new)
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "SUCCESS: Patch applied"
} else {
    Write-Host "NOT FOUND: Pattern not matched"
    # Try to find where the second fetchRemoteMedia is
    $idx = $content.IndexOf('const fetched = await fetchRemoteMedia({')
    if ($idx -ge 0) {
        Write-Host "Found at index: $idx"
        Write-Host "Context:"
        Write-Host $content.Substring($idx, 300)
    }
}
