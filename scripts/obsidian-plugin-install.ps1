# UI Automation: Install Obsidian community plugins
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Get-ObsidianWindow {
    $proc = Get-Process -Name "Obsidian" -ErrorAction SilentlyContinue
    if ($proc) {
        $hwnd = $proc.MainWindowHandle
        if ($hwnd -ne [IntPtr]::Zero) {
            return [System.Windows.Forms.WindowFromPoint]::new($hwnd)
        }
    }
    return $null
}

Write-Host "Looking for Obsidian window..."
$obsidian = Get-Process -Name "Obsidian" -ErrorAction SilentlyContinue
if ($obsidian) {
    Write-Host "Found Obsidian (PID: $($obsidian.Id), Handle: $($obsidian.MainWindowHandle))"
    
    # Give it time to fully load
    Start-Sleep -Seconds 2
    
    # Try to bring to foreground
    SetForegroundWindow $obsidian.MainWindowHandle
    Start-Sleep -Milliseconds 500
    
    # Open Settings: Ctrl+,
    Write-Host "Sending Ctrl+, to open Settings..."
    [System.Windows.Forms.SendKeys]::SendWait("^{,}")
    Start-Sleep -Seconds 2
    
    # Search for "community plugins"
    Write-Host "Searching for Community Plugins..."
    [System.Windows.Forms.SendKeys]::SendWait("community plugins")
    Start-Sleep -Seconds 1
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Start-Sleep -Seconds 2
    
    Write-Host "Settings should be open. Manual steps needed:"
    Write-Host "1. Look for 'Community Plugins' in the left sidebar"
    Write-Host "2. Click on it"
    Write-Host "3. Click 'Turn on community plugins' if shown"
    Write-Host "4. Search for 'Calendar' and click Install"
    Write-Host "5. Search for 'RSS Reader' and click Install"
    Write-Host "6. Enable both plugins from the Installed tab"
} else {
    Write-Host "Obsidian process not found"
}

# Also try URI approach
Write-Host ""
Write-Host "Trying obsidian:// URIs..."
try {
    Start-Process "obsidian://show-plugin?id=obsidian-calendar-plugin"
    Write-Host "Calendar plugin URI sent"
} catch {
    Write-Host "Calendar URI failed: $_"
}

Start-Sleep -Seconds 2
try {
    Start-Process "obsidian://show-plugin?id=obsidian-rss-reader"
    Write-Host "RSS plugin URI sent"
} catch {
    Write-Host "RSS URI failed: $_"
}

Write-Host ""
Write-Host "Done. Please complete the installation in Obsidian UI."
