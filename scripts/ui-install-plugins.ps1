Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName UIAutomationClient

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Continue'

# Helper to send text safely
function Send-Text($text) {
    Start-Sleep -Milliseconds 100
    [System.Windows.Forms.SendKeys]::SendWait($text)
}

# Helper to send key
function Send-Key($key) {
    Start-Sleep -Milliseconds 100
    [System.Windows.Forms.SendKeys]::SendWait($key)
}

# Bring Obsidian to foreground
Write-Host "Looking for Obsidian..."
$obsidian = Get-Process -Name "Obsidian" -ErrorAction SilentlyContinue
if (-not $obsidian) {
    Write-Host "Starting Obsidian..."
    $exe = 'E:\software\Obsidian\Obsidian.exe'
    if (Test-Path $exe) {
        Start-Process -FilePath $exe -ArgumentList "--open-vault `"E:\software\Obsidian\vault`""
        Start-Sleep -Seconds 5
        $obsidian = Get-Process -Name "Obsidian" -ErrorAction SilentlyContinue
    }
}

if ($obsidian) {
    Write-Host "Obsidian found (PID: $($obsidian.Id))"
    Start-Sleep -Seconds 2
    
    # Try to maximize and bring to front
    $hwnd = $obsidian.MainWindowHandle
    if ($hwnd -ne [IntPtr]::Zero) {
        Write-Host "Window handle: $hwnd"
        
        # Maximize window
        ShowWindow $hwnd 3
        Start-Sleep -Milliseconds 300
        
        # Bring to front
        SetForegroundWindow $hwnd
        Start-Sleep -Milliseconds 500
    }

    # Open Settings with Ctrl+,
    Write-Host "Opening Settings (Ctrl+,)..."
    Send-Key "^{,}"
    Start-Sleep -Seconds 3
    
    # Type "community plugins" to search
    Write-Host "Searching for community plugins..."
    Send-Text "community plugins"
    Start-Sleep -Seconds 1
    Send-Key "{ENTER}"
    Start-Sleep -Seconds 2
    
    # Navigate: look for Community Plugins option
    # Try Tab to navigate
    Write-Host "Trying to navigate to Community Plugins..."
    for ($i = 0; $i -lt 5; $i++) {
        Send-Key "{TAB}"
        Start-Sleep -Milliseconds 200
    }
    
    Write-Host ""
    Write-Host "=== Manual Steps Needed ==="
    Write-Host "Obsidian should now be in focus with Settings open."
    Write-Host ""
    Write-Host "In the Settings sidebar, look for:"
    Write-Host "  'Community Plugins' (under 'Plugin Options' or similar)"
    Write-Host ""
    Write-Host "Steps in Obsidian:"
    Write-Host "  1. Click 'Community Plugins' in the left sidebar"
    Write-Host "  2. Click 'Turn on community plugins' button (if shown)"
    Write-Host "  3. In the search box, type: Calendar"
    Write-Host "  4. Click 'Install' next to 'Calendar' plugin"
    Write-Host "  5. Search for: RSS"
    Write-Host "  6. Click 'Install' next to 'RSS Reader' plugin"
    Write-Host "  7. Enable both from the 'Installed' tab"
    Write-Host ""
    Write-Host "Plugin IDs to search:"
    Write-Host "  - Calendar: 'obsidian-calendar-plugin' by liamcain"
    Write-Host "  - RSS: 'RSS Reader' or 'Feeds' by Kirill Muzykov"
    
    # Try direct URI to open community plugins browser
    Write-Host ""
    Write-Host "Trying obsidian://install-plugin URL..."
    Start-Process "obsidian://install-plugin/obsidian-calendar-plugin"
    Start-Sleep -Seconds 2
    Start-Process "obsidian://install-plugin/obsidian-rss-reader"
    Start-Sleep -Seconds 2
    
} else {
    Write-Host "Obsidian not running and could not start!"
}

Write-Host "Done."
