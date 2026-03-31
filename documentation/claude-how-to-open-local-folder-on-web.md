# How to Open a Local Folder in Windows Explorer from a Browser-Based Web App

## Q: Is it possible to add a "Go" button that opens File Explorer when clicked?

**Context:** A local markdown viewer (`md.htm`) runs at `http://127.0.0.1:5500`. When a markdown table contains a `source folder` row (e.g. `C:\Works\Python\RestClientGUI`), the goal is to show a **Go** button that opens that folder directly in Windows Explorer.

---

## The Problem

Browsers sandbox web pages from the OS filesystem. From an `http://` page you **cannot**:

- Call `window.open('file:///C:/path')` — blocked by modern browsers when origin is `http://`
- Use `shell:` or `explorer:` protocols — not standard / blocked
- Invoke `explorer.exe` directly — no OS access from browser JS

---

## The Solution: Custom Windows URL Protocol Handler

Register a custom URI scheme (e.g. `openexplorer:`) in the Windows Registry. The browser sees it as a protocol (like `mailto:` or `tel:`), asks Windows to handle it, and Windows runs the registered handler — a PowerShell script that calls `explorer.exe`.

### Flow

```
User clicks "Go" button
  → window.location.href = 'openexplorer:C:\Works\Python\RestClientGUI'
  → Browser passes to Windows (registry lookup)
  → PowerShell script receives "openexplorer:C:\Works\Python\RestClientGUI"
  → Script strips prefix → calls: explorer.exe "C:\Works\Python\RestClientGUI"
  → Windows Explorer opens the folder
```

---

## Implementation

### 1. `open-explorer.ps1` — Protocol Handler Script

```powershell
# open-explorer.ps1
param([string]$url)

try {
    $path = $url -replace '^openexplorer:', ''
    $path = [System.Uri]::UnescapeDataString($path)
    $path = $path -replace '/', '\'

    if (Test-Path $path) {
        Start-Process explorer.exe -ArgumentList $path
    } else {
        $parent = Split-Path $path -Parent
        if ($parent -and (Test-Path $parent)) {
            Start-Process explorer.exe -ArgumentList $parent
        }
    }
} catch {
    Write-Error "open-explorer.ps1 failed: $_"
}
```

Place this at: `C:\Works\md\powershell\open-explorer.ps1`

---

### 2. `register-explorer-protocol.reg` — Registry Registration

```reg
Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\openexplorer]
@="URL:Open Explorer Protocol"
"URL Protocol"=""

[HKEY_CLASSES_ROOT\openexplorer\shell\open\command]
@="powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File \"C:\\Works\\md\\open-explorer.ps1\" \"%1\""
```

**One-time setup:** Double-click this `.reg` file and confirm the UAC prompt.

---

### 3. JavaScript in `md.htm` — Detect Table Row and Inject Button

```javascript
function addSourceFolderGoButton() {
    $('table').each(function () {
        var $table = $(this);
        var folderPath = null;

        $table.find('tr').each(function () {
            var $cells = $(this).find('td');
            if ($cells.length >= 2) {
                var label = $cells.first().text().trim().toLowerCase();
                if (label === 'source folder') {
                    folderPath = $cells.eq(1).text().trim();
                    return false; // break
                }
            }
        });

        if (folderPath) {
            var path = folderPath;
            var $btn = $('<button class="btn btn-outline-danger btn-sm" style="margin-top:8px;">Go</button>');
            $btn.on('click', function () {
                window.location.href = 'openexplorer:' + path;
            });
            $table.after($btn);
        }
    });
}
```

Call it after `zero-md` renders: `addSourceFolderGoButton();`

---

## Markdown Table Format

The button appears automatically when a table has a row with `source folder` in the first column:

```markdown
| item          | desc                          |
|---------------|-------------------------------|
| source folder | C:\Works\Python\RestClientGUI |
| github URL    | https://github.com/...        |
```

---

## Why Not Other Approaches?

| Approach | Why It Doesn't Work |
|---|---|
| `window.open('file:///C:/path')` | Blocked by browser security from `http://` origin |
| `shell:` protocol | IE/Edge legacy only, blocked in modern browsers |
| Local HTTP server (e.g. Node.js on port 5502) | Works, but requires running a separate process |
| Clipboard copy only | No real Explorer open, just copies the path |
| Electron wrapper | Would work, but changes the entire app architecture |

**Custom protocol handler** is the best balance: one-time registry setup, no server needed, works in Chrome/Edge/Firefox on Windows.

---

## Alternatives (If Registry Is Not an Option)

**Clipboard fallback:** Copy the path and show a toast message instead of opening Explorer.

```javascript
$btn.on('click', function () {
    navigator.clipboard.writeText(path).then(function () {
        showToast('Path copied! Open Explorer and paste in the address bar.');
    });
});
```
