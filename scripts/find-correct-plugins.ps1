$ErrorActionPreference = 'Continue'
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Try obsidian://install-plugin URIs for both plugins
# This is the official way Obsidian handles plugin installation
$plugins = @(
    "obsidian-calendar-plugin",
    "obsidian-rss"  # joethei/obsidian-rss
)

Write-Host "Sending install requests to Obsidian..."
foreach ($p in $plugins) {
    Write-Host "  Requesting: obsidian://install-plugin/$p"
    try {
        Start-Process "obsidian://install-plugin/$p"
        Start-Sleep -Milliseconds 500
    } catch {
        Write-Host "    Error: $_"
    }
}

Start-Sleep -Seconds 3

# Check if Obsidian is running and bring it forward
$proc = Get-Process -Name "Obsidian" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($proc) {
    Write-Host ""
    Write-Host "Obsidian is running (PID: $($proc.Id))"
    $hwnd = $proc.MainWindowHandle
    if ($hwnd -ne [IntPtr]::Zero) {
        Add-Type @"
using System;
using System.Runtime.InteropServices;
public class CFG {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int s);
}
"@
        [CFG]::ShowWindow($hwnd, 9)
        Start-Sleep -Milliseconds 300
        [CFG]::SetForegroundWindow($hwnd)
        Write-Host "Window brought to foreground"
    }
}

Write-Host ""
Write-Host "=== Expected Result ==="
Write-Host "obsidian://install-plugin/ URLs should have triggered Obsidian's"
Write-Host "built-in plugin installer. If you're seeing a dialog in Obsidian,"
Write-Host "follow the prompts to confirm installation."
Write-Host ""
Write-Host "If nothing happened, please:"
Write-Host "  1. Open Obsidian manually"
Write-Host "  2. Press Ctrl+, to open Settings"
Write-Host "  3. Click 'Community Plugins' in the sidebar"
Write-Host "  4. Search for and install 'Calendar' and 'RSS'"
