# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is `md.htm` — a single-file HTML markdown viewer used as a personal documentation tool. It renders markdown files (via `?src=path/to/file.md` URL parameter) in the browser with a rich toolbar. Served by VS Code Live Server on port 5500 during development. Deployed to `home.moh93.com` in production.

## File Structure

```
md.htm              — Main application (HTML + inline JS, ~1000+ lines)
md-main.css         — Main stylesheet
github.css          — GitHub markdown theme override
moh93-custom.css    — Production-only CSS (loaded conditionally for moh93 project)
js/
  copy-clipboard-button.js  — "Copy Password" button logic for <pre> blocks
  moh93-custom.js           — Production-specific custom functions
  md-main.js                — Legacy stub (not actively used)
dist/
  photoswipe*.js/.css       — PhotoSwipe image lightbox (local copy)
  jspdf/jspdf-251.js        — jsPDF for PDF export
  jspdf/html2canvas.js      — html2canvas for PDF export
zero-md-main/       — Local copy of the zero-md web component source (upstream project, not modified)
agents/
  planning-agent.md         — Feature backlog / TODO tracker
  analyer.md                — Go button keyword spec
  planner-documentation.md  — Architecture/feature documentation
  docs/                     — Detailed feature docs and how-tos
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

* Do not delete # TODO section text automatically. I will move them to # DONE section when done.
