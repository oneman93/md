# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is `md.htm` — a single-file HTML markdown viewer used as a personal documentation tool. It renders markdown files (via `?src=path/to/file.md` URL parameter) in the browser with a rich toolbar. Served by VS Code Live Server on port 5500 during development. Deployed to `home.moh93.com` in production.

## File Structure

```
md.htm                      — Main application (HTML + inline JS, ~2600+ lines)
md-main.css                 — Main stylesheet
github.css                  — GitHub markdown theme override
moh93-custom.css            — Production-only CSS (loaded conditionally for moh93 project)
version-history.md          — Version changelog (displayed in toolbar)
sample.md                   — Sample markdown for testing
md-20251231.htm             — Archived snapshot from 2025-12-31

js/
  copy-clipboard-button.js  — "Copy Password" button + blur logic for <pre> blocks
  moh93-custom.js           — Production-specific custom functions
  md-main.js                — Legacy stub (not actively used)

dist/
  photoswipe.esm.js         — PhotoSwipe image lightbox (local copy)
  photoswipe-lightbox.esm.js
  photoswipe.css
  umd/                      — UMD builds of PhotoSwipe
  jspdf/jspdf-251.js        — jsPDF for PDF export
  jspdf/html2canvas.js      — html2canvas for PDF export

images/                     — Favicon and icon assets

powershell/
  upload-to-conf.ps1        — Upload images to Confluence as attachments
  open-explorer.ps1         — Open Windows Explorer via openexplorer: protocol
  register-conf-upload-protocol.reg  — Register confupload: protocol
  register-explorer-protocol.reg     — Register openexplorer: protocol
  launch-upload.vbs         — VBS launcher for PowerShell upload

tmp/
  copy2conf-debug.log       — Debug log written by PowerShell upload
  copy2conf-status.json     — Progress status for Copy2Conf upload polling

zero-md-main/               — Local copy of zero-md source (upstream, do NOT modify)

agents/
  planner-md.md             — Feature backlog / TODO tracker (NEVER delete #TODO text)
  analyer.md                — Go button keyword spec
  planner-documentation.md  — Architecture/feature documentation
  docs/                     — Detailed feature docs and how-tos
  imgs/                     — Screenshots for bug reports and feature specs
  credentials/              — Confluence credentials (gitignored)
```

## Architecture

`md.htm` is a self-contained single-file app. The rendering pipeline:

1. URL param `?src=path.md` is read on load
2. A `<zero-md>` element is created dynamically, pointing to `src`
3. zero-md renders the markdown into a shadow DOM
4. `md.htm` clones the shadow DOM content into `#mdcontainer` as a `<zero-md-clone>` element (to allow direct DOM access for features like Copy, search, etc.)
5. Post-render hooks run: `wrapImagesWithPhotoswipe()`, `addSourceFolderGoButton()`, `addBannerCredentialCopyButtons()`, copy-code buttons, Mermaid detection, etc.

Key inline JS sections in `md.htm` (search by function name):
- `CopyHTMLToClipboard()` — Copy rendered HTML to clipboard
- `CopyHTMLToClipboard2Conf()` — Copy2Conf: strips images/local links, prepares for Confluence paste
- `showConfSettings()` / `saveConfSettingsAndCopy()` — Confluence Settings dialog (stores Base URL, email, API token, page ID in localStorage)
- `addSourceFolderGoButton()` — detects folder-path keywords in table cells (see `agents/analyer.md` for keyword list) and injects "Go" buttons that open Windows Explorer via `openexplorer:` protocol
- `addBannerCredentialCopyButtons()` — in `js/copy-clipboard-button.js`; adds "Copy Password" buttons to `<pre>` blocks containing `Password:` text
- `showH1Only()` / H1 filter dropdown — filters visible headings; state persisted in localStorage
- Table nav sidebar — collapsible floating panel listing all tables
- Mermaid — detects `<pre>` near headings containing "flow"/"diagram", adds "Create Mermaid" button

## External Dependencies (CDN)

- `zero-md@2` — markdown rendering web component
- jQuery 3.6.1
- Bootstrap 4.3.1 CSS
- github-markdown-css@4 + PrismJS@1 (loaded by zero-md for code highlighting)
- Mermaid (latest via jsdelivr)
- Font Awesome (kit `33b67b9684`)

## Development

Open `md.htm` via VS Code Live Server (`http://127.0.0.1:5500/md/md.htm?src=...`). No build step required — all code is vanilla HTML/CSS/JS.

To test with a specific markdown file:
```
http://127.0.0.1:5500/md/md.htm?src=../path/to/file.md
```

The `code` button (opens file in VS Code) works in Edge but requires a one-time protocol permission in Chrome (`chrome://settings/content/handlers`).

## Moh93 Production Detection

`window._isMoh93Project` is set at page load based on whether the hostname starts with `home.moh93.com` or the `src` param is a full URL. This gates loading of `moh93-custom.css` and `moh93-custom.js`.

## Key Conventions

- `#mdcontainer` is the rendered output container — all post-render DOM manipulation targets this element
- localStorage keys: `ls-click-history`, `ls-expanded-nth`, `ls-search-text`, `ls-is-wrapper`, `conf-settings`
- The `agents/planning-agent.md` file tracks feature backlog. `# TODO` section must NOT be deleted or struck through — user moves items manually to `# DONE`
- `zero-md-main/` is an upstream snapshot — do not modify it; `md.htm` loads zero-md from CDN

# Rule

## TODO section

* When I ask you to do `# todo` section, do not delete or strike through #todo section text. Do not change `# todo` to `# done`. For example,
```
do @planner-work-index.md #todo
```
command should not delete or strike through text in the corresponding section, eg, `# TODO - more changes`. It will not change the section title either, eg, into `# DONE - more changes`.

* Whenever doing #todo section, if found any empty references in the file of #todo, eg, [], run /md-fill-empty-reference command to fill them.

* If more than 1 `#todo` section is found in the file, ask the user to confirm which one to work on before proceeding. Do not waste time doing unnecessary `#todo` sections.

## QnA

* When a question is asked in markdown file with `q.`, answer the question in the same file not in command line.

## Code suggestion

* When you give me answer with **sql query**, **bash script** etc, please give a clean code without `>` between the multiple lines.

## C:\Works

* C:\Works code environment should never be killed to open other projects.

## SQL project

* For sql tasks, do not deploy any code to sql server directly.
* Scripts to deploy will be saved into `/agents/sql-claude` folder.

## ConnectionString

* Project specific sql server connection string will be given here:

```
here
```

* Default database will be given here:
```
here
```

## BAU documentation

* Remember this section into MEMORY.md including referenced scripts.

### BAU file name and location

* Bau document should be created in `C:\Works\_LoadingDocuments\`
* Bau document file name should contain `bau` and `{projectName}`. For example, if it is a `bau` document about `masterdata`, the file name should start `masterdata-bau-`.
* Bau document should use template: `C:\Works\_LoadingDocuments\BAU\bau-template.md` and update content.

### Referenced images and videos

* All image in `Pictures` folder will be moved to `C:\Works\_LoadingDocuments\imgs\img-{projectName}` folder using scripts in `/c/Users/matthew.oh/scripts` - `move2containing` or `cdr` and referenced in the markdown file.
  * [](./agents/imgs/errors/image-not-copied.png)
  * [](./matthew.oh/scripts/move2containing)
  * [](./matthew.oh/scripts/cdr)
* All videos in `Pictures` folder will be moved to [OneDrive](./matthew.oh/OneDrive%20-%20Torrens%20Global%20Education/LocalVideos/) and the shared link will be referenced in the markdown file. The share people scope and level are:
  * [](./agents/imgs/share.png)
  * [](./agents/imgs/share-level.png)
* Any file in `Pictures` starting with `z` should be excluded for copying and referencing.

### Bau file reference

* The created bau file should be referenced in [](./_work-index.md).
* If [](./_work-index.md) has a parent loading file eg, `masterdata-bau-loading.md`, the reference should be created on the parent file.
* Otherwise, if [](./_work-index.md) has the project section, it should make a reference on the top of the matching project, eg, `# MasterData`.
* Otherwise, make reference on the top of [](./_work-index.md).

## Coding Standards
- Always wrap API calls in try/catch and capture errors with meaningful messages

## Mermaid diagram

* Always draw simple flow chart not a complicated sequence diagram unless specified.

# File structure

* Remember that there are two html tags under `div.mdcontainer`:
  * `zero-md`
  * `zero-md-clone`
* Most (all) of html tags changes are happening in `zero-md-clone` with jquery.
