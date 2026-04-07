$path = "C:\Users\Administrator\AppData\Roaming\npm\node_modules\openclaw-cn\dist\telegram\bot\delivery.js"
$content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

# Replace allowedHostnames with allowPrivateNetwork
$content = $content.Replace(
    'ssrfPolicy: { allowedHostnames: ["api.telegram.org"] }',
    'ssrfPolicy: { allowPrivateNetwork: true }'
)

[System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
Write-Host "Updated ssrfPolicy to allowPrivateNetwork"
