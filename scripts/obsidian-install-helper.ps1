Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder lpString, int nMaxCount);
}
"@

Add-Type -AssemblyName System.Windows.Forms

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Continue'

$vaultPath = 'E:\software\Obsidian\vault'

# Try obsidian://install-plugin URIs
Write-Host "=== Opening Obsidian Plugin Installer ==="
Write-Host ""

$pluginUrls = @(
    "obsidian://install-plugin/obsidian-calendar-plugin",
    "obsidian://install-plugin/obsidian-rss-reader"
)

foreach ($url in $pluginUrls) {
    Write-Host "Opening: $url"
    try {
        Start-Process $url
        Write-Host "  OK - Obsidian should open plugin installer"
    } catch {
        Write-Host "  FAIL: $_"
    }
}

Start-Sleep -Seconds 3

# Now open the vault if not already open
Write-Host ""
Write-Host "Opening vault: $vaultPath"
Start-Process "E:\software\Obsidian\Obsidian.exe" -ArgumentList "--open-vault `"$vaultPath`""
Start-Sleep -Seconds 4

# Bring Obsidian window to front
$obsidian = Get-Process -Name "Obsidian" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($obsidian) {
    $hwnd = $obsidian.MainWindowHandle
    if ($hwnd -ne [IntPtr]::Zero) {
        Write-Host "Window handle: $hwnd"
        
        # Restore if minimized
        if ([Win32]::IsIconic($hwnd)) {
            Write-Host "Window is minimized, restoring..."
            [Win32]::ShowWindow($hwnd, 9)  # SW_RESTORE
            Start-Sleep -Milliseconds 500
        }
        
        # Maximize
        [Win32]::ShowWindow($hwnd, 3)  # SW_MAXIMIZE
        Start-Sleep -Milliseconds 300
        
        # Bring to front
        [Win32]::SetForegroundWindow($hwnd)
        Start-Sleep -Milliseconds 500
        Write-Host "Window should now be in foreground"
    }
}

Write-Host ""
Write-Host "=== Next Steps ==="
Write-Host ""
Write-Host "1. Obsidian should be in front with the vault open"
Write-Host "2. Press Ctrl+, (or Cmd+, on Mac) to open Settings"
Write-Host "3. In the left sidebar, click 'Community Plugins'"
Write-Host "4. Click 'Turn on community plugins' (if shown)"
Write-Host "5. Search for and install:"
Write-Host "   - 'Calendar' by liamcain"
Write-Host "   - 'RSS Reader' by Kirill Muzykov"
Write-Host ""
Write-Host "OR simply open these links in your browser:"
Write-Host "https://obsidian.md/plugins?id=obsidian-calendar-plugin"
Write-Host "https://obsidian.md/plugins?id=obsidian-rss-reader"
