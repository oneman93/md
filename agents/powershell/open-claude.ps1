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

# Open Claude CLI in Windows Terminal if available, otherwise fall back to cmd
$wtExe = Get-Command "wt.exe" -ErrorAction SilentlyContinue
if ($wtExe) {
    Start-Process "wt.exe" "-d `"$folderPath`" cmd /k claude"
} else {
    Start-Process "cmd.exe" "/k cd /d `"$folderPath`" && claude"
}
