# btnConfigSettings — Copy2Conf Settings & Upload Architecture

## Overview

The `⚙` (gear) button (`btnConfSettings`) opens a settings dialog where the user enters
Confluence credentials. These are stored in `localStorage` and used by the Copy2Conf button
to upload images to Confluence via a PowerShell relay.

---

## File Structure

```
md/
├── md.htm                              # Main app — UI + all JS logic
└── powershell/
    ├── register-conf-upload-protocol.reg  # One-time setup: registers confupload: Windows protocol
    ├── launch-upload.vbs               # Called by confupload: protocol — launches PS hidden
    ├── upload-to-conf.ps1              # Main upload script (downloads images, uploads to Confluence)
    ├── open-explorer.ps1               # Separate: used by Go button (openexplorer: protocol)
    ├── register-explorer-protocol.reg  # One-time setup for Go button openexplorer: protocol
    │
    │   -- UNUSED (can be deleted) --
    ├── copy-to-conf.ps1                # Old staging-folder approach — NOT referenced in md.htm
    └── register-conf-protocol.reg      # Registers copytoconf: for copy-to-conf.ps1 — NOT used
```

---

## Function Flow

### 1. One-time setup
User double-clicks `register-conf-upload-protocol.reg` → registers `confupload:` as a Windows
custom URL protocol pointing to `launch-upload.vbs`.

### 2. Settings dialog (`btnConfSettings` / `⚙` button)
```
showConfSettings()        reads localStorage['conf-settings'] → populates form fields
saveConfSettingsAndCopy() saves { baseUrl, email, apiToken, pageId, uploadImages } to localStorage
                          then calls CopyHTMLToClipboard2Conf()
```

### 3. Copy2Conf button flow (`CopyHTMLToClipboard2Conf`)
```
buildConf2Clone()
  ├── snapshot absolute img.src URLs from live DOM
  ├── cloneNode(contentRoot)
  ├── apply absolute URLs to cloned imgs
  ├── remove content below "Do not copy from here" heading
  ├── remove entire <li>/<p> lines containing .md links
  ├── replace .mp4 link text (keep line)
  └── replace <img> with empty <p> (unwrap <a> wrappers first)

CopyHTMLToClipboard2Conf()
  ├── if settings.uploadImages AND local images found:
  │     write JSON packet { settings, html } to clipboard
  │     window.location.href = 'confupload:run'
  │       → browser triggers confupload: protocol
  │       → Windows runs launch-upload.vbs (hidden)
  │       → vbs runs upload-to-conf.ps1 (hidden PowerShell)
  │           ├── reads JSON packet from clipboard
  │           ├── GET existing attachments (to update, not duplicate)
  │           ├── foreach localhost img src:
  │           │     WebClient.DownloadData(srcUrl) → raw bytes
  │           │     HttpClient + ByteArrayContent → POST multipart to Confluence REST API
  │           │     replace localhost URL in HTML with versioned attachment URL (?api=v2)
  │           ├── writes progress to tmp/copy2conf-status.json
  │           └── Set-HtmlClipboard (CF_HTML format) → puts final HTML in clipboard
  │     JS polls tmp/copy2conf-status.json every 1.5s → shows "Uploading N/total" toast
  │     when complete=true → dismisses toast
  └── else (no upload / no local images):
        copyCloneToClipboard(clone) → execCommand('copy') directly
```

---

## Unused Files (can be deleted)

| File | Reason |
|------|--------|
| `copy-to-conf.ps1` | Old approach: copied images to a staging folder for manual drag. Never triggered from md.htm. |
| `register-conf-protocol.reg` | Registers `copytoconf:` for the above unused script. |

---

## "Preview unavailable" — Root Cause

**When:** Confluence Cloud changed this behaviour around **April 2026** (confirmed by user: worked until ~1 month before May 2026).

**What changed:** Confluence's Fabric editor paste handler stopped auto-fetching and uploading
`<img src>` URLs from clipboard HTML. Previously (up to ~April 2026), pasting HTML with
`<img src="localhost:...">` caused the Fabric editor to fetch each image and upload it as a
page attachment. This no longer happens.

**Why Fabric editor?** Atlassian migrated from TinyMCE to Fabric editor in Confluence Cloud
around 2019–2021. TinyMCE auto-uploaded pasted images. Fabric editor was supposed to do the
same via a compatibility layer — that compatibility layer was removed in ~April 2026.

**Current limitation:** Even with images correctly uploaded as Confluence attachments via the
PowerShell API, pasting `<img src="https://company.atlassian.net/download/attachments/...?api=v2">`
still shows "Preview unavailable". Confluence's media preview service fetches the image
server-side (not via the user's browser session), so authentication fails.

**Working workaround:** Drag images individually from md.htm directly into Confluence's Edit
view. Confluence then uploads each image as a permanent blob attachment.

**Current Copy2Conf behaviour (post April 2026):** Copies text-only HTML (images replaced with
empty `<p>` placeholders). User pastes text into Confluence, then drags images manually.
