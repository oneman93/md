# open-explorer.ps1
# Registered as Windows custom protocol handler for "openexplorer:"
# Usage: powershell -File open-explorer.ps1 "openexplorer:C:\some\path"

param([string]$url)

try {
    # Strip the protocol prefix (e.g. "openexplorer:")
    $path = $url -replace '^openexplorer:', ''

    # URL-decode in case the browser encoded slashes or spaces
    $path = [System.Uri]::UnescapeDataString($path)

    # Normalize: replace forward slashes with backslashes
    $path = $path -replace '/', '\'

    if (Test-Path $path -PathType Container) {
        # It's a folder — open it directly
        Start-Process explorer.exe -ArgumentList $path
    } elseif (Test-Path $path -PathType Leaf) {
        # It's a file — open with default application (e.g. SSMS for .sql, Excel for .xlsx)
        Start-Process $path
    } else {
        # Path doesn't exist — open parent if possible, else show error
        $parent = Split-Path $path -Parent
        if ($parent -and (Test-Path $parent)) {
            Start-Process explorer.exe -ArgumentList $parent
        } else {
            [System.Windows.Forms.MessageBox]::Show("Path not found: $path", "Open Explorer")
        }
    }
} catch {
    Write-Error "open-explorer.ps1 failed: $_"
}
