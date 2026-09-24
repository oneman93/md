# open-claude.ps1
# Opens VS Code in a new window at the given folder AND starts Claude CLI
# in a new Windows Terminal (or cmd) session at that folder.
#
# Called by the "openclaude:" custom URL protocol registered via
# register-claude-protocol.reg

param([string]$RawArg)

# Strip protocol prefix and decode URI
$folderPath = $RawArg -replace '^openclaude:/+', ''
$folderPath = [System.Uri]::UnescapeDataString($folderPath)
# Normalise path separators
$folderPath = $folderPath -replace '/', '\'
# Strip trailing backslash
$folderPath = $folderPath.TrimEnd('\')

if (-not $folderPath) { exit }

# Open VS Code in a new window (does not kill existing windows)
Start-Process "code" "--new-window `"$folderPath`""

# Wait for VS Code to load
Start-Sleep -Seconds 4
$wshShell = New-Object -ComObject WScript.Shell
$wshShell.AppActivate("Visual Studio Code")
Start-Sleep -Milliseconds 800

# Open Claude in the right side terminal
$wshShell.SendKeys("^+p")
Start-Sleep -Milliseconds 800
$wshShell.SendKeys("Claude Code: Open in Terminal")
Start-Sleep -Milliseconds 500
$wshShell.SendKeys("{ENTER}")
