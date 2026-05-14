# DONE

# 'Go' button

* You create `Go` button when you look at the key words [](#key-words) in table.

* The key text [](#key-words) are case insensitive.
* If you find multiple text of above list, you will create multiple button for each of the text `<td>` value
* The button order should be same as `<td>` order in `<tr>`
* The button text will be `Go {folder path}`. For example, if source folder is C:\Works, then button text will be `Go C:\Works`.

## Key words

  * `source folder`
  * `source`
  * `local folder`
  * `folder`
  * `local`

## Samples

* Following example <td> values should show Go button:
  * Local source folder
  * C# Source folder
  * C# Source folder 2
  * Git folder

# Go button update

* See [](./imgs/go-button-update.png)
* Instead of creating 3 go buttons on bottom, create each `Go` button next to the path, within the same <tr> with a separate <td> column.
* And the text is just `Go` instead of `Go {path}` because the previous <td> column already has the path.
* Table css seems breaking [](./imgs/errors/table-breaking.png)
* Table css still breaking [](./imgs/errors/table-breaking2.png) -> number of <td> should be all the same inside <table>

# Table sidebar

* See [](./imgs/table-sidebar.png)
* Let table side bar has eg, `x` button to close and restore.
* On page load, by default, the table side bar should be collapsed.


# Show H1 Only

* After function `showH1Only()` in [](../md.htm), it seems <h1> text size becomes smaller. Keep it as original <h1> size.
* See [](./imgs/errors/why-not-collapsed.png)
* Why the text inside red rectagle not collapsed although they were not <h1>?
* The full text of screenshot is given [here](./docs/planner-sql-archive-sample.md)
* Hide <h3> as well when `Show H1 Only` button clicked.
* `Show H1 Only` state - <h1> only or show all - be remembered even after page refresh.

# Copy code

* See [](./imgs/copy-code.png) 
* If <pre> text, add `Copy code` button on top right. When clicked, the text inside <pre> will be copied to clipboard.
* See [](./imgs/errors/copy-code-ui.png): copy code button should be hidden on `Show H1 Only` mode.
* See [](./imgs/errors/button-still-show.png): copy code button still shows in `Show H1 Only` mode.

# `code` button

* Move `code` button to `divRight` section as the first button:
  * [](./imgs/ui-code-button.png)
* When clicked, open visual code to edit the matching markdown file of the url.
* For example, if current url is `http://127.0.0.1:5500/md/md.htm?src=_LoadingDocuments%2Fclone-date-loading.md`, open code to edit `c:\works\_LoadingDocuments%2Fclone-date-loading.md`
* Button clicking does not do anything.
  * Leave console js log after line 902 in [](../md.htm) to confirm that it ran successfully.
  * [](./imgs/ui-menu/code-does-nothing.png)
```
  window.location.href = 'vscode://file/' + filePath;
```
* Clicking `code` button still does nothing. Add log in line 899 as well.
* After popup screen, [](./imgs/ui-menu/code-does-nothing.png), there is no js log in console. Investigate.
* Still does nothing [](./imgs/ui-menu/does-nothing2.png). Url seems correct though. It does not open markdown file in vscode. It does not show js log in chrome console.
* Edge worked perfectly:
  * [](./imgs/ui-menu/edge-wroked.png)
  * [](./imgs/ui-menu/edge-worked2.png)
* But Chrome did nothing.

```
  Chrome blocks external protocol launches unless explicitly permitted. The fix is a one-time Chrome setting:

  Option 1 — In the Chrome dialog:
  Next time the "Open Visual Studio Code?" dialog appears, check "Always allow http://127.0.0.1:5500 to open links of this type" before clicking "Open Visual Studio Code".

  Option 2 — Chrome settings:
  Go to chrome://settings/content/handlers and add vscode:// as an allowed handler for 127.0.0.1:5500.

  The current code (location.href = vsCodeUrl) is the correct implementation — it works in Edge and will work in Chrome once the protocol is allowed. No code change needed.
```

* `vscode` protocol does not work directly from `chrome` url.
```
vscode://file///c:/works/_LoadingDocuments/synctool-release-note.md
```
* Restore `btnCode` button

# UI - `Wrap with md.html` 
* `Wrap with md.html` button wraps `href` url with `?src=xxx.md` paraemter. This url modification should not be applied to other protocol eg, `vscode`.
* For example, below href url should not be changed by `Wrap with md.html` button:
```
<!-- Simple Link -->
<a href="vscode://file/C:/works/_LoadingDocuments/synctool-release-note.md">Open File in VS Code (you have to unwrap)</a>
```



# UI - version number

* Version number should show right to Home button:
  * [](./imgs/ui-menu/version1.png) is correct
  * [](./imgs/ui-menu/version2.png) is incorrect.


# UI - `Copy password` button

* Move copy password button from outside of `<pre>` to inside of `<pre>` next to `Copy code` button:
  * [](./imgs/copy-password-btn.png)
* Copy password button is still in old position outside of <pre> tag.
  * [](./imgs/errors/still-out-pre.png)
  * Add js console log if debug is required.


* Update `Copy code` button to have same height as `Copy password`:
  * [](./imgs/copy-code-vs-pass.png)
* Both buttons seemed growing height and still different height:
  * [](./imgs/errors/btn-height.png)
* Make these two buttons small button.
  * [](./imgs/errors/small-btn.png)



# UI - Blur password value

* `extractPasswordFromPre()` extracts password value. When <pre> has password values, blur those text by css.
* Copy password button will copy text value correctly as it is.



# UI - favicon etc

* Let favicon be something interesting not just plain document icon:
  * [](./imgs/favicon.png)
  * I like your new [](./imgs/new-favicon.png), but let `md` text be yellow-ish color.
* Let `Go` button be `btn-info` color theme:
  * [](./imgs/go-theme.png)

# DONE

# `inputSearch` text box fire

* `inputSearch-triggers.md` written.
* Fix: `keyup` guarded with `if (isSearchPage)`, non-search pages get empty value on load.

# Folder icon

* Opens Windows Explorer with the image file selected via `openexplorer:` protocol.
* Fix: use `imgLast[0].src` (absolute URL) instead of `imgLast.attr('src')` (may be relative).

# Do not copy from here

* Already case-insensitive: `headingTextLower.includes(stopMarkerTexts[j].toLowerCase())`.

# Copy2Conf — image placeholder + link line removal

* `.md` links: remove entire `<li>` or `<p>` container (not just the link text).
* `.mp4` links: replace link with plain text, keep the line.
* Images: unwrap PhotoSwipe `<a>` wrapper first, then replace `<img>` with empty `<p>`.
* Empty `<p>` keeps section structure (so H1 headings don't disappear in Confluence paste).

# Copy2Conf — link filtering

* `.md` and `.mp4` links replaced with plain text (link removed, text kept).
* External links (e.g. `https://torrens.atlassian.net/...`) kept as-is.
* Regex: `/\.md(\?|#|&|$)/` and `/\.mp4(\?|#|&|$)/` to avoid false positives.

# Copy2Conf — text only (no image upload)

* Copy2Conf now strips all `<img>` elements before copying to clipboard.
* No PowerShell upload triggered. User drags images manually into Confluence.
* `btnConfigSettings` kept as-is.

# Copy2Conf URL fix

* Simple URL (no params) → 404 on Confluence Cloud. `api=v2` param is required.
* Fix: use full versioned URL from API response (`?version=N&modificationDate=...&api=v2`).
* Root cause of "Preview unavailable": Confluence Fabric editor treats pasted `<img src>` as external images, not internal attachments. It does not auto-convert to `<ac:image>` references, so previews from Confluence's media service fail.
* Workaround that works: drag images individually from md.htm into Confluence Edit view (Confluence uploads as blob attachment).

# Copy2Conf

* Root cause: Confluence migrated from TinyMCE editor to Fabric editor.
  * Old TinyMCE: auto-uploaded pasted images as page attachments (why it used to work).
  * New Fabric editor: uses `src` URL as-is, does NOT fetch/upload on paste.
* Fix applied:
  * Unwrapped PhotoSwipe `<a class="photoswipe">` wrappers so images render (not shown as link text).
  * Changed container from `#mdcontainer` to `zero-md-clone > div.all` to avoid duplicate invisible content.
* Current state: images show in Confluence while local server is running.
* Known limitation: images disappear when server is off (localhost URLs).
* Permanent workaround: drag individual images from md.htm page to Confluence — Confluence fetches and uploads as attachment (blob → permanent file). Cannot be automated via clipboard API (browser security prevents putting binary file data in clipboard HTML for multiple images).

# Go button `` handling

* Sometimes, path is quoted with quotation or even presented as unix format. Below samples should be interpreted to a path:

```
/c/Users/matthew.oh/scripts
`/c/Users/matthew.oh/scripts`
-> C:\Works\matthew.oh\scripts
```

# DONE

* I have hard time in:
* id.atlassian.com → Security → API tokens
* id.atlassian.com redirects to:
```
https://home.atlassian.com/o/38fbec1d-48cd-4024-91f7-7ab0e7bd4766/?utm_source=identity&cloudId=cf0e281f-66b6-4a6f-ac30-d393342753a4
```
* Do not delete # TODO section automatically. I will move them to # DONE section when done.
* I got image upload error [](./imgs/errors/image-upload-error.png)
* I got another error [](./imgs/errors/image-upload-error2.png)
* I got error [](./imgs/errors/powershell-error.png)
* Succeed on setting button, but when copied to confluence, images do not show:
  * [](./imgs/errors/no-image1.png)
  * [](./imgs/errors/no-image2.png)
* Image still broken: 
  * [](./imgs/errors/no-image3.png)
* Also keep popup dialog showing [](./imgs/errors/pop-up-keep.png) until success message comes up.
* Still failed:
  * [](./imgs/errors/failed.png)
  * Some were showing because of localhost: [](./imgs/errors/some-were-showing.png)
  * No localhost image should be showing.
* Still no image shows [](./imgs/errors/still-no-image.png)
* Uploading popup does not show any progress. Show 1/27, 2/27 ... etc
* When success dialog comes up, the popup can hide.
  * [](./imgs/errors/uploading-does-not-progress.png)
* Image still corrupted:
  * [](./imgs/errors/image-corrupt.png)
* Still not working [](./imgs/errors/v4-fail.png)
* Don't you need some logs to confirm?
* Image still not showing. Review with log files:
  * [](./imgs/errors/fail1.png)
  * [](./imgs/errors/fail2.png)
  * [](../tmp/copy2conf-debug.log)
  * [](../tmp/copy2conf-status.json)
* Waited 1 min, but no good:
  * [](./imgs/errors/wait1min.png)
  * [](./imgs/errors/wait1min2.png)
* Now I got [](./imgs/errors/grm-error.png)


# Mermaid

* When you see <pre> section, add `Create Mermaid` button on top right corner, if the nearest <h1> title contains text eg, `flow` or `diagram`.
* When button clicked, the text inside <pre> will be converted mermaid text and shows mermaid diagram on popup.
* Popup dialog will have mermaid image on load. The popup will have 3 buttons - view code, copy code, png.
	* view code will show mermaid syntax
	* copy code will copy mermaid syntax
	* png will save current diagram into png and download
* See [](./imgs/errors/mermaid-not-working.png)
* Mermaid syntax and diagram are not created dynamically from the <pre> text.
* See [](./imgs/errors/open-new-tab.png)
* Diagram dialog is too small. Instead of dialog, open a new tab. If necessary, create a temporary markdown file.
* See [](./imgs/errors/png-button-not-working.png)
* png button not working

# Git push

* Git push is not working fix please.


# Misc

* See [](./imgs/errors/i-didnt-type.png)
* It shows my email in search text box. I don't know where it comes from.
* It still show. When local storage is empty, show empty string.
* Can you not allow email in this search box? User will never enter email to search text here.
* See [](./imgs/errors/this-happens.png)
* After page refresh, sometimes this happens.
* I think it may happen because of `btnConfigSettings` button: [](./imgs/errors/i-think-it.png)
* See [](./imgs/img-err-menu/h2-not-show.png)
* What makes the first few lines not showing on localhost website? 
* See [](./imgs/img-err-menu/meta-data.png)
* It still shows on top with small fonts. It seems `## q1` is treated as meta data.



# Show H1 Only
* When this button clicked, show little dropdown next to the button having checkbox items:
  * H1
  * H2
  * H3
* When each item ticked, render the markdown file to show matching items.
* For example, if `H1, H2` selected, show all `<h1>` and `<h2>` items only in markdown.
* See [](./imgs/img-err-menu/each-h2.png)
  * Each <h2> and <h3> should have expand/collapse button, preferably, with smaller icons than <h1>
  * <h1> Collapse button does not work
  * `Show H1 Only` has the last item, `Show All` button, when clicked, it will show the page without any filtering.
* See [](./imgs/img-err-menu/expand-h2-notworking.png)
  * <h2> expand not working
  * Please update icons with better css - icon is not intuitive.
  * Mininum js logs if needed debugging.
* See screenshots below. Expand not working in <h1> and <h2>
  * [](./imgs/img-err-menu/q1-expand-not.png)
  * [](./imgs/img-err-menu/q1-expand-not2.png)
* Fix [](./imgs/img-err-menu/h2-not-working.png)
* If `h1, h2, h3` has children text to show by expanding, do not show `expand` icon. In [](./imgs/img-err-menu/nothing-to-expand.png), the first <h1> should not show expand button.

# Search box

* See [](./imgs/errors/page-load-after.png)
* Search box text box is not editable right after page load. It seems being locked for a while. If it is locked, show text box css as disabled.
* Find the root issue why the textbox was locked.

# TODO

* See [](./imgs/img-ui/title-green.png)
* Instead of making title xxx.md into <h1>, make it bootstrap dark green color like comments/information.
* Do not convert the title xxx.md into <h1>. Just change color.
* Do not convert the title xxx.md into small size. No cess except color. Color should be brighter green as in [](./imgs/img-ui/color.png)