# Plan

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

* Created `code` button next to `Go Home` button on top.
* When clicked, open visual code to edit the matching markdown file of the url.
* For example, if current url is `http://127.0.0.1:5500/md/md.htm?src=_LoadingDocuments%2Fclone-date-loading.md`, open code to edit `c:\works\_LoadingDocuments%2Fclone-date-loading.md`